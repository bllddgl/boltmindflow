import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/stats_snapshot.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/result.dart';
import '../supabase_client.dart';

class SupabaseStatsRepository implements StatsRepository {
  SupabaseStatsRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<StatsSnapshot>> getSnapshot({required DateTime from, required DateTime to}) async {
    try {
      final fromStr = from.toIso8601String();
      final toStr = to.toIso8601String();

      final rows = await _db.from('reading_sessions')
          .select('started_at, ended_at, words_read, avg_wpm, focus_score')
          .gte('started_at', fromStr)
          .lte('started_at', toStr);

      if (rows.isEmpty) {
        return Result.success(StatsSnapshot(
          windowStart: from,
          windowEnd: to,
          totalReadingTime: Duration.zero,
          avgWpm: 0,
          wordsRead: 0,
          booksCompleted: 0,
          focusScore: 1.0,
          currentStreakDays: 0,
          dailyMinutes: List.filled(to.difference(from).inDays + 1, 0),
        ));
      }

      int totalWords = 0;
      int totalWpm = 0;
      double totalFocus = 0;
      int totalMinutes = 0;
      final dayMinutes = <String, int>{};

      for (final row in rows) {
        final words = (row['words_read'] as num).toInt();
        final wpm = (row['avg_wpm'] as num).toInt();
        final focus = (row['focus_score'] as num).toDouble();
        final started = DateTime.parse(row['started_at'] as String);
        final ended = row['ended_at'] != null ? DateTime.parse(row['ended_at'] as String) : null;

        totalWords += words;
        totalWpm += wpm;
        totalFocus += focus;

        final minutes = ended != null ? ended.difference(started).inMinutes : (words / wpm).round();
        totalMinutes += minutes;

        final dayKey = '${started.year}-${started.month}-${started.day}';
        dayMinutes[dayKey] = (dayMinutes[dayKey] ?? 0) + minutes;
      }

      final dayCount = to.difference(from).inDays + 1;
      final dailyMinutes = List.generate(dayCount, (i) {
        final day = from.add(Duration(days: i));
        final key = '${day.year}-${day.month}-${day.day}';
        return dayMinutes[key] ?? 0;
      });

      final completedRows = await _db.from('documents')
          .select('id')
          .neq('last_read_at', 'null');

      return Result.success(StatsSnapshot(
        windowStart: from,
        windowEnd: to,
        totalReadingTime: Duration(minutes: totalMinutes),
        avgWpm: rows.isEmpty ? 0 : (totalWpm ~/ rows.length),
        wordsRead: totalWords,
        booksCompleted: completedRows.length,
        focusScore: rows.isEmpty ? 1.0 : (totalFocus / rows.length),
        currentStreakDays: await _computeStreak(),
        dailyMinutes: dailyMinutes,
      ));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  Future<int> _computeStreak() async {
    try {
      final rows = await _db.from('reading_sessions')
          .select('started_at')
          .order('started_at', ascending: false)
          .limit(500);

      if (rows.isEmpty) return 0;

      final days = <String>{};
      for (final row in rows) {
        final dt = DateTime.parse(row['started_at'] as String);
        days.add('${dt.year}-${dt.month}-${dt.day}');
      }

      var streak = 0;
      var cursor = DateTime.now();
      while (days.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Result<int>> getCurrentStreak() async {
    final streak = await _computeStreak();
    return Result.success(streak);
  }

  @override
  Future<Result<void>> logEvent({
    required String type,
    String? documentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _db.from('stats_events').insert({
        'event_type': type,
        'document_id': documentId,
        'payload': payload,
      });
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }
}
