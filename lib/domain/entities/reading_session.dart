/// One reading session, from play to pause/finish.
///
/// [focusScore] is 0..1, lowered by rewinds and long pauses — an honest proxy
/// for engagement, not a gimmick.
class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.documentId,
    required this.startedAt,
    required this.endedAt,
    required this.wordsRead,
    required this.blocksRead,
    required this.avgWpm,
    required this.focusScore,
  });

  final String id;
  final String documentId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int wordsRead;
  final int blocksRead;
  final int avgWpm;
  final double focusScore;

  Duration? get duration => endedAt?.difference(startedAt);
  bool get isFinished => endedAt != null;
}
