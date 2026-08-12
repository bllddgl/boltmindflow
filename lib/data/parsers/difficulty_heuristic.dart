import '../../domain/entities/content_block.dart';

/// Cheap heuristic to estimate paragraph difficulty for adaptive speed.
///
/// Factors: average word length (longer = harder) and sentence length
/// (longer = harder). Not a linguistic model — just enough signal for the
/// RSVP engine to slow down on dense passages.
Difficulty estimateDifficulty(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return Difficulty.easy;

  final words = RegExp(r'\S+').allMatches(trimmed).toList();
  if (words.isEmpty) return Difficulty.easy;

  final wordCount = words.length;
  final totalChars = words.fold(0, (sum, m) => sum + m[0]!.length);
  final avgWordLen = totalChars / wordCount;

  final sentences = RegExp(r'[.!?]+').allMatches(trimmed);
  final sentenceCount = sentences.isEmpty ? 1 : sentences.length;
  final avgSentenceLen = wordCount / sentenceCount;

  final score = avgWordLen * 0.5 + (avgSentenceLen / 20) * 0.5;

  if (score > 7.0) return Difficulty.hard;
  if (score > 5.5) return Difficulty.medium;
  return Difficulty.easy;
}
