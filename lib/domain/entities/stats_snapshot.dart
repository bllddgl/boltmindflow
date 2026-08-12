/// An aggregated snapshot of reading statistics over a time window.
class StatsSnapshot {
  const StatsSnapshot({
    required this.windowStart,
    required this.windowEnd,
    required this.totalReadingTime,
    required this.avgWpm,
    required this.wordsRead,
    required this.booksCompleted,
    required this.focusScore,
    required this.currentStreakDays,
    required this.dailyMinutes,
  });

  final DateTime windowStart;
  final DateTime windowEnd;
  final Duration totalReadingTime;
  final int avgWpm;
  final int wordsRead;
  final int booksCompleted;
  final double focusScore; // 0..1
  final int currentStreakDays;

  /// Minutes read per day, for bar charts. Length = days in window.
  final List<int> dailyMinutes;
}
