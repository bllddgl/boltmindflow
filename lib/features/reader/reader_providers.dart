import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/rsvp_engine.dart';
import '../../core/engine/rsvp_events.dart';
import '../../core/engine/rsvp_scheduler.dart';
import '../../data/di/data_providers.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/user_settings.dart';

/// Live display state — what the UI shows on each tick.
class DisplayState {
  const DisplayState({
    this.text = '',
    this.blockIndex = 0,
    this.blockType,
    this.isPlaying = false,
    this.isPaused = false,
    this.isFinished = false,
    this.progress = 0.0,
    this.wordsRead = 0,
    this.totalWords = 0,
    this.stats,
  });

  final String text;
  final int blockIndex;
  final Type? blockType;
  final bool isPlaying;
  final bool isPaused;
  final bool isFinished;
  final double progress;
  final int wordsRead;
  final int totalWords;
  final RsvpStats? stats;

  DisplayState copyWith({
    String? text,
    int? blockIndex,
    Type? blockType,
    bool? isPlaying,
    bool? isPaused,
    bool? isFinished,
    double? progress,
    int? wordsRead,
    int? totalWords,
    RsvpStats? stats,
  }) {
    return DisplayState(
      text: text ?? this.text,
      blockIndex: blockIndex ?? this.blockIndex,
      blockType: blockType ?? this.blockType,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
      progress: progress ?? this.progress,
      wordsRead: wordsRead ?? this.wordsRead,
      totalWords: totalWords ?? this.totalWords,
      stats: stats ?? this.stats,
    );
  }
}

/// Controller that owns the [RsvpEngine] lifecycle and bridges events to
/// [DisplayState] for the UI. Created by the screen widget with its own
/// [TickerProvider] vsync.
class ReaderController extends StateNotifier<DisplayState> {
  ReaderController(this._ref, this._documentId, this._vsync)
      : super(const DisplayState());

  final Ref _ref;
  final String _documentId;
  final TickerProvider _vsync;

  RsvpEngine? _engine;
  StreamSubscription<RsvpEvent>? _subscription;
  String? _sessionId;
  int _totalWords = 0;
  List<ContentBlock> _blocks = [];
  RsvpSettings _settings = RsvpSettings.defaults();

  Future<void> load() async {
    final loadDoc = _ref.read(loadDocumentProvider);
    final result = await loadDoc(_documentId);

    result.when(
      success: (data) async {
        _totalWords = data.document.wordCount;
        _blocks = data.blocks;

        // Load user settings
        final settingsResult = await _ref.read(getSettingsProvider).call();
        settingsResult.when(
          success: (s) => _settings = s.rsvp,
          failure: (_) {},
        );

        // Start a reading session
        final startReading = _ref.read(startReadingProvider);
        final sessionResult = await startReading(_documentId);
        sessionResult.when(
          success: (session) => _sessionId = session.id,
          failure: (_) {},
        );

        // Create the engine
        final scheduler = TickerScheduler(_vsync);
        _engine = RsvpEngine(scheduler: scheduler);
        _engine!.load(
          blocks: _blocks,
          settings: _settings,
          startBlock: data.document.lastPosition,
        );

        _subscription = _engine!.events.listen(_onEvent);

        state = DisplayState(
          totalWords: _totalWords,
          blockIndex: data.document.lastPosition,
        );
      },
      failure: (f) {
        // State stays at default — UI shows error
      },
    );
  }

  void play() {
    _engine?.play();
    state = state.copyWith(isPlaying: true, isPaused: false);
  }

  void pause() {
    _engine?.pause();
    state = state.copyWith(isPlaying: false, isPaused: true);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void rewind(int n) => _engine?.rewind(n);
  void skip(int n) => _engine?.skip(n);
  void jumpToBlock(int index) => _engine?.jumpToBlock(index);

  Future<void> bookmark() async {
    final addBookmark = _ref.read(addBookmarkProvider);
    await addBookmark(
      documentId: _documentId,
      blockIndex: state.blockIndex,
    );
  }

  Future<void> savePosition() async {
    final savePos = _ref.read(savePositionProvider);
    await savePos(_documentId, state.blockIndex);
  }

  void updateSettings(RsvpSettings settings) {
    _settings = settings;
    if (_engine == null) return;
    _engine!.load(blocks: _blocks, settings: settings, startBlock: state.blockIndex);
  }

  void _onEvent(RsvpEvent event) {
    switch (event) {
      case TickEvent(:final chunk):
        state = state.copyWith(
          text: chunk.displayText,
          blockIndex: chunk.blockIndex,
          blockType: chunk.blockType,
          wordsRead: _engine?.wordsRead ?? state.wordsRead,
          progress: _totalWords > 0
              ? (_engine?.wordsRead ?? 0) / _totalWords
              : 0.0,
        );
      case BlockChangedEvent(:final blockIndex):
        state = state.copyWith(blockIndex: blockIndex);
        _savePositionDebounced();
      case PausedEvent():
        state = state.copyWith(isPlaying: false, isPaused: true);
      case ResumedEvent():
        state = state.copyWith(isPlaying: true, isPaused: false);
      case FinishedEvent(:final stats):
        state = state.copyWith(
          isPlaying: false,
          isFinished: true,
          stats: stats,
          progress: 1.0,
        );
        _endSession(stats);
      case ErrorEvent():
        break;
    }
  }

  Timer? _saveTimer;
  void _savePositionDebounced() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () => savePosition());
  }

  Future<void> _endSession(RsvpStats stats) async {
    await savePosition();
    if (_sessionId != null) {
      final endReading = _ref.read(endReadingProvider);
      await endReading(
        sessionId: _sessionId!,
        wordsRead: stats.wordsRead,
        blocksRead: stats.blocksRead,
        avgWpm: stats.avgWpm,
        focusScore: stats.focusScore,
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _subscription?.cancel();
    _engine?.dispose();
    super.dispose();
  }
}
