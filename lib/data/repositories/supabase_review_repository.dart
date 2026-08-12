import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/review_card.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/result.dart';
import '../mappers.dart';
import '../supabase_client.dart';

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<List<ReviewCard>>> getDueCards({DateTime? asOf}) async {
    try {
      final cutoff = (asOf ?? DateTime.now()).toIso8601String();
      final rows = await _db.from('review_cards')
          .select()
          .lte('due_at', cutoff)
          .order('due_at', ascending: true);
      return Result.success(rows.map(Mappers.reviewCardFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<List<ReviewCard>>> getCardsForDocument(String documentId) async {
    try {
      final rows = await _db.from('review_cards')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: false);
      return Result.success(rows.map(Mappers.reviewCardFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<ReviewCard>> createCard({
    required String documentId,
    required ReviewCardType type,
    required String front,
    required String back,
  }) async {
    try {
      final row = await _db.from('review_cards').insert({
        'document_id': documentId,
        'card_type': type.name,
        'front': front,
        'back': back,
      }).select().single();
      return Result.success(Mappers.reviewCardFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<ReviewCard>> gradeCard(String cardId, {required ReviewGrade grade}) async {
    try {
      final row = await _db.from('review_cards')
          .select()
          .eq('id', cardId)
          .maybeSingle();
      if (row == null) return const Result.failure(NotFoundFailure());

      final card = Mappers.reviewCardFromRow(row);
      final updated = _applySm2(card, grade);

      final updatedRow = await _db.from('review_cards')
          .update({
            'ease': updated.ease,
            'interval_days': updated.intervalDays,
            'repetitions': updated.repetitions,
            'due_at': updated.dueAt.toIso8601String(),
          })
          .eq('id', cardId)
          .select()
          .single();
      return Result.success(Mappers.reviewCardFromRow(updatedRow));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<void>> deleteCard(String cardId) async {
    try {
      await _db.from('review_cards').delete().eq('id', cardId);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  /// SM-2 spaced repetition algorithm.
  ({double ease, int intervalDays, int repetitions, DateTime dueAt}) _applySm2(
    ReviewCard card,
    ReviewGrade grade,
  ) {
    var ease = card.ease;
    var reps = card.repetitions;
    var interval = card.intervalDays;

    switch (grade) {
      case ReviewGrade.again:
        reps = 0;
        interval = 0;
        ease = (ease - 0.2).clamp(1.3, 5.0);
      case ReviewGrade.hard:
        ease = (ease - 0.15).clamp(1.3, 5.0);
        interval = reps == 0 ? 1 : (interval * ease * 0.8).round();
        reps += 1;
      case ReviewGrade.good:
        interval = switch (reps) {
          0 => 1,
          1 => 3,
          _ => (interval * ease).round(),
        };
        reps += 1;
      case ReviewGrade.easy:
        ease = (ease + 0.15).clamp(1.3, 5.0);
        interval = switch (reps) {
          0 => 2,
          1 => 6,
          _ => (interval * ease * 1.3).round(),
        };
        reps += 1;
    }

    final dueAt = DateTime.now().add(Duration(days: interval));
    return (ease: ease, intervalDays: interval, repetitions: reps, dueAt: dueAt);
  }
}
