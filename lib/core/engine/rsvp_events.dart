import '../../domain/entities/content_block.dart';
import '../../domain/entities/user_settings.dart';

/// A chunk of words to display in one RSVP tick.
class RsvpChunk {
  const RsvpChunk({
    required this.words,
    required this.blockIndex,
    required this.blockType,
    required this.difficulty,
    required this.duration,
  });

  final List<String> words;
  final int blockIndex;
  final Type blockType;
  final Difficulty? difficulty;
  final Duration duration;

  int get wordCount => words.length;
  String get displayText => words.join(' ');
  bool get isImage => blockType == ImageBlock;
}

/// Events emitted by the RSVP engine.
sealed class RsvpEvent {
  const RsvpEvent();
}

class TickEvent extends RsvpEvent {
  const TickEvent(this.chunk);
  final RsvpChunk chunk;
}

class BlockChangedEvent extends RsvpEvent {
  const BlockChangedEvent(this.block, this.blockIndex);
  final ContentBlock block;
  final int blockIndex;
}

class PausedEvent extends RsvpEvent {
  const PausedEvent(this.position, this.wordsRead);
  final int position;
  final int wordsRead;
}

class ResumedEvent extends RsvpEvent {
  const ResumedEvent(this.position);
  final int position;
}

class FinishedEvent extends RsvpEvent {
  const FinishedEvent(this.stats);
  final RsvpStats stats;
}

class ErrorEvent extends RsvpEvent {
  const ErrorEvent(this.message);
  final String message;
}

/// Aggregated stats for a finished session.
class RsvpStats {
  const RsvpStats({
    required this.wordsRead,
    required this.blocksRead,
    required this.avgWpm,
    required this.focusScore,
    required this.elapsed,
  });

  final int wordsRead;
  final int blocksRead;
  final int avgWpm;
  final double focusScore; // 0..1
  final Duration elapsed;
}

/// Engine state.
enum RsvpState { idle, playing, paused, finished }
