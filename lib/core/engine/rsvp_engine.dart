import 'dart:async';

import '../../domain/entities/content_block.dart';
import '../../domain/entities/user_settings.dart';
import 'rsvp_events.dart';
import 'rsvp_scheduler.dart';

/// The RSVP reading engine.
///
/// Pure logic for word chunking, timing, and state management. A
/// [RsvpScheduler] is injected so tests run instantly without real timers.
/// The engine emits [RsvpEvent]s via a [Stream] that the UI subscribes to.
///
/// State machine: idle → playing → paused → finished.
///   - play() from idle/paused → playing
///   - pause() from playing → paused
///   - rewind(n) from playing/paused → stays in current state, moves position
///   - finish() from any state → finished
class RsvpEngine {
  RsvpEngine({
    required RsvpScheduler scheduler,
  }) : _scheduler = scheduler;

  final RsvpScheduler _scheduler;
  final StreamController<RsvpEvent> _controller = StreamController<RsvpEvent>.broadcast();

  Stream<RsvpEvent> get events => _controller.stream;

  // Configuration
  List<ContentBlock> _blocks = [];
  RsvpSettings _settings = RsvpSettings.defaults();
  int _startBlock = 0;

  // State
  RsvpState _state = RsvpState.idle;
  int _blockIndex = 0;
  int _chunkIndexInBlock = 0;
  List<RsvpChunk> _chunks = [];
  int _wordsRead = 0;
  int _blocksRead = 0;
  int _rewindCount = 0;
  int _pauseCount = 0;
  DateTime _startedAt = DateTime.now();
  Duration _elapsed = Duration.zero;

  RsvpState get state => _state;
  int get blockIndex => _blockIndex;
  int get wordsRead => _wordsRead;
  int get blocksRead => _blocksRead;
  int get totalBlocks => _blocks.length;
  int get totalWords => _blocks.fold(0, (sum, b) => sum + b.wordCount);
  bool get isPlaying => _state == RsvpState.playing;
  bool get isPaused => _state == RsvpState.paused;
  bool get isFinished => _state == RsvpState.finished;

  /// Load content and settings into the engine. Must be called before play().
  void load({
    required List<ContentBlock> blocks,
    required RsvpSettings settings,
    int startBlock = 0,
  }) {
    if (_state == RsvpState.playing) {
      throw StateError('Cannot load while playing');
    }
    _blocks = blocks;
    _settings = settings;
    _startBlock = startBlock.clamp(0, blocks.length - 1);
    _blockIndex = _startBlock;
    _chunkIndexInBlock = 0;
    _chunks = [];
    _wordsRead = 0;
    _blocksRead = 0;
    _rewindCount = 0;
    _pauseCount = 0;
    _elapsed = Duration.zero;
    _state = RsvpState.idle;
  }

  /// Start or resume reading.
  void play() {
    switch (_state) {
      case RsvpState.idle:
        _startedAt = DateTime.now();
        _state = RsvpState.playing;
        _prepareCurrentBlock();
        _scheduleNextTick();
      case RsvpState.paused:
        _state = RsvpState.playing;
        _controller.add(ResumedEvent(_globalChunkIndex()));
        _scheduleNextTick();
      case RsvpState.playing:
        return; // already playing
      case RsvpState.finished:
        throw StateError('Cannot play after finished');
    }
  }

  /// Pause reading.
  void pause() {
    if (_state != RsvpState.playing) return;
    _scheduler.cancel();
    _state = RsvpState.paused;
    _pauseCount++;
    _controller.add(PausedEvent(_globalChunkIndex(), _wordsRead));
  }

  /// Rewind by [n] chunks.
  void rewind(int n) {
    if (_chunks.isEmpty) return;
    _rewindCount++;

    for (var i = 0; i < n; i++) {
      if (_chunkIndexInBlock > 0) {
        _chunkIndexInBlock--;
      } else if (_blockIndex > 0) {
        _blockIndex--;
        _prepareCurrentBlock();
        _chunkIndexInBlock = _chunks.length - 1;
      }
    }

    if (_state == RsvpState.playing) {
      _scheduler.cancel();
      _scheduleNextTick();
    }
  }

  /// Skip forward by [n] chunks.
  void skip(int n) {
    for (var i = 0; i < n; i++) {
      if (_chunkIndexInBlock < _chunks.length - 1) {
        _chunkIndexInBlock++;
      } else if (_blockIndex < _blocks.length - 1) {
        _blockIndex++;
        _prepareCurrentBlock();
        _chunkIndexInBlock = 0;
      }
    }

    if (_state == RsvpState.playing) {
      _scheduler.cancel();
      _scheduleNextTick();
    }
  }

  /// Jump to a specific block.
  void jumpToBlock(int index) {
    final clamped = index.clamp(0, _blocks.length - 1);
    _blockIndex = clamped;
    _chunkIndexInBlock = 0;
    _prepareCurrentBlock();

    if (_state == RsvpState.playing) {
      _scheduler.cancel();
      _scheduleNextTick();
    }
  }

  /// Finish the session.
  void finish() {
    _scheduler.cancel();
    _state = RsvpState.finished;
    _controller.add(FinishedEvent(_computeStats()));
  }

  /// Dispose resources.
  void dispose() {
    _scheduler.cancel();
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _prepareCurrentBlock() {
    if (_blockIndex >= _blocks.length) {
      finish();
      return;
    }

    final block = _blocks[_blockIndex];
    _chunks = _buildChunksForBlock(block);
    _chunkIndexInBlock = 0;
    _controller.add(BlockChangedEvent(block, _blockIndex));
  }

  List<RsvpChunk> _buildChunksForBlock(ContentBlock block) {
    final wpm = _effectiveWpm(block);
    final wordsPerDisplay = _settings.wordsPerDisplay;
    final minDuration = const Duration(milliseconds: 200);

    return switch (block) {
      HeadingBlock(:final text, :final level) => [
        RsvpChunk(
          words: [text],
          blockIndex: _blockIndex,
          blockType: HeadingBlock,
          difficulty: null,
          duration: _durationForWords(1, wpm, minDuration) * 2,
        ),
      ],
      ParagraphBlock(:final text, :final difficulty) =>
        _chunkText(text, wordsPerDisplay, wpm, minDuration, _blockIndex, difficulty),
      ListBlock(:final items) => items.map((item) => RsvpChunk(
        words: [item.text],
        blockIndex: _blockIndex,
        blockType: ListBlock,
        difficulty: null,
        duration: _durationForWords(item.wordCount, wpm, minDuration),
      )).toList(),
      QuoteBlock(:final text, :final attribution) => [
        ..._chunkText(text, _settings.wordsPerDisplay, wpm, minDuration, _blockIndex, null),
        if (attribution != null)
          RsvpChunk(
            words: [attribution],
            blockIndex: _blockIndex,
            blockType: QuoteBlock,
            difficulty: null,
            duration: _durationForWords(1, wpm, minDuration),
          ),
      ],
      CodeBlock(:final code) => [
        RsvpChunk(
          words: [code],
          blockIndex: _blockIndex,
          blockType: CodeBlock,
          difficulty: null,
          duration: _durationForWords(code.split(RegExp(r'\s+')).length, wpm, minDuration) * 3,
        ),
      ],
      ImageBlock(:final assetPath, :final caption, :final displayDuration) => [
        RsvpChunk(
          words: [caption ?? ''],
          blockIndex: _blockIndex,
          blockType: ImageBlock,
          difficulty: null,
          duration: displayDuration ?? _settings.imageDuration,
        ),
      ],
      FootnoteBlock(:final text) =>
        _chunkText(text, wordsPerDisplay, wpm, minDuration, _blockIndex, null),
      CaptionBlock(:final text) =>
        _chunkText(text, wordsPerDisplay, wpm, minDuration, _blockIndex, null),
      FormulaBlock(:final latex) => [
        RsvpChunk(
          words: [latex],
          blockIndex: _blockIndex,
          blockType: FormulaBlock,
          difficulty: null,
          duration: _durationForWords(1, wpm, minDuration) * 2,
        ),
      ],
      TableBlock() => [
        RsvpChunk(
          words: [block.wordCount.toString()],
          blockIndex: _blockIndex,
          blockType: TableBlock,
          difficulty: null,
          duration: _durationForWords(block.wordCount, wpm, minDuration) * 2,
        ),
      ],
    };
  }

  List<RsvpChunk> _chunkText(
    String text,
    int wordsPerDisplay,
    int wpm,
    Duration minDuration,
    int blockIdx,
    Difficulty? difficulty,
  ) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    final chunks = <RsvpChunk>[];
    for (var i = 0; i < words.length; i += wordsPerDisplay) {
      final chunkWords = words.sublist(i, (i + wordsPerDisplay).clamp(0, words.length));
      chunks.add(RsvpChunk(
        words: chunkWords,
        blockIndex: blockIdx,
        blockType: ParagraphBlock,
        difficulty: difficulty,
        duration: _durationForWords(chunkWords.length, wpm, minDuration),
      ));
    }
    return chunks;
  }

  Duration _durationForWords(int wordCount, int wpm, Duration minDuration) {
    if (wordCount == 0 || wpm == 0) return minDuration;
    final ms = (wordCount / wpm * 60 * 1000).round();
    return Duration(milliseconds: ms).clamp(minDuration, const Duration(seconds: 30));
  }

  int _effectiveWpm(ContentBlock block) {
    if (!_settings.adaptiveSpeed) return _settings.targetWpm;

    final difficulty = switch (block) {
      ParagraphBlock(:final difficulty) => difficulty,
      _ => Difficulty.medium,
    };

    return switch (difficulty) {
      Difficulty.easy => (_settings.targetWpm * 1.1).round(),
      Difficulty.medium => _settings.targetWpm,
      Difficulty.hard => (_settings.targetWpm * 0.85).round(),
    };
  }

  void _scheduleNextTick() {
    if (_state != RsvpState.playing) return;
    if (_chunks.isEmpty || _chunkIndexInBlock >= _chunks.length) {
      _advanceBlock();
      return;
    }

    final chunk = _chunks[_chunkIndexInBlock];
    _scheduler.schedule(chunk.duration, _onTick);
  }

  void _onTick() {
    if (_state != RsvpState.playing) return;
    if (_chunkIndexInBlock >= _chunks.length) {
      _advanceBlock();
      return;
    }

    final chunk = _chunks[_chunkIndexInBlock];
    _wordsRead += chunk.wordCount;
    _controller.add(TickEvent(chunk));

    _chunkIndexInBlock++;
    if (_chunkIndexInBlock >= _chunks.length) {
      _blocksRead++;
      _advanceBlock();
    } else {
      _scheduleNextTick();
    }
  }

  void _advanceBlock() {
    _blockIndex++;
    if (_blockIndex >= _blocks.length) {
      finish();
      return;
    }
    _prepareCurrentBlock();
    if (_state == RsvpState.playing) {
      _scheduleNextTick();
    }
  }

  int _globalChunkIndex() {
    var global = 0;
    for (var i = 0; i < _blockIndex && i < _blocks.length; i++) {
      global += _blocks[i].wordCount;
    }
    global += _chunkIndexInBlock;
    return global;
  }

  RsvpStats _computeStats() {
    final elapsed = DateTime.now().difference(_startedAt);
    final minutes = elapsed.inSeconds / 60;
    final avgWpm = minutes > 0 ? (_wordsRead / minutes).round() : 0;

    // Focus score: start at 1.0, subtract for rewinds and pauses
    var focus = 1.0;
    focus -= _rewindCount * 0.05;
    focus -= _pauseCount * 0.02;
    focus = focus.clamp(0.0, 1.0);

    return RsvpStats(
      wordsRead: _wordsRead,
      blocksRead: _blocksRead,
      avgWpm: avgWpm,
      focusScore: focus,
      elapsed: elapsed,
    );
  }
}
