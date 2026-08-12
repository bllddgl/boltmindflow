import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/result.dart';
import '../mappers.dart';
import '../supabase_client.dart';

class SupabaseReadingRepository implements ReadingRepository {
  SupabaseReadingRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<ReadingSession>> startSession(String documentId) async {
    try {
      final row = await _db.from('reading_sessions').insert({
        'document_id': documentId,
      }).select().single();
      return Result.success(Mappers.sessionFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<ReadingSession>> endSession(
    String sessionId, {
    required int wordsRead,
    required int blocksRead,
    required int avgWpm,
    required double focusScore,
  }) async {
    try {
      final row = await _db.from('reading_sessions')
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'words_read': wordsRead,
            'blocks_read': blocksRead,
            'avg_wpm': avgWpm,
            'focus_score': focusScore,
          })
          .eq('id', sessionId)
          .select()
          .single();
      return Result.success(Mappers.sessionFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<List<ReadingSession>>> getSessionsForDocument(String documentId) async {
    try {
      final rows = await _db.from('reading_sessions')
          .select()
          .eq('document_id', documentId)
          .order('started_at', ascending: false);
      return Result.success(rows.map(Mappers.sessionFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<ReadingSession?>> getLastSession(String documentId) async {
    try {
      final row = await _db.from('reading_sessions')
          .select()
          .eq('document_id', documentId)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return const Result.success(null);
      return Result.success(Mappers.sessionFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<Bookmark>> addBookmark({
    required String documentId,
    required int blockIndex,
    String? label,
  }) async {
    try {
      final row = await _db.from('bookmarks').insert({
        'document_id': documentId,
        'block_index': blockIndex,
        'label': label,
      }).select().single();
      return Result.success(Mappers.bookmarkFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<void>> removeBookmark(String bookmarkId) async {
    try {
      await _db.from('bookmarks').delete().eq('id', bookmarkId);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<List<Bookmark>>> getBookmarks(String documentId) async {
    try {
      final rows = await _db.from('bookmarks')
          .select()
          .eq('document_id', documentId)
          .order('block_index', ascending: true);
      return Result.success(rows.map(Mappers.bookmarkFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }
}
