import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/result.dart';
import '../mappers.dart';
import '../supabase_client.dart';

class SupabaseDocumentRepository implements DocumentRepository {
  SupabaseDocumentRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<List<Document>>> getAll({bool includeArchived = false}) async {
    try {
      var query = _db.from('documents').select().order('imported_at', ascending: false);
      if (!includeArchived) query = query.eq('is_archived', false);
      final rows = await query;
      return Result.success(rows.map(Mappers.documentFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<Document>> getById(String id) async {
    try {
      final row = await _db.from('documents').select().eq('id', id).maybeSingle();
      if (row == null) return const Result.failure(NotFoundFailure());
      return Result.success(Mappers.documentFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<Document>> importDocument({
    required String filePath,
    required String title,
    String? author,
    required String format,
  }) async {
    try {
      final row = await _db.from('documents').insert({
        'title': title,
        'author': author,
        'source_path': filePath,
        'source_format': format,
      }).select().single();
      return Result.success(Mappers.documentFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<void>> deleteDocument(String id) async {
    try {
      await _db.from('documents').delete().eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<Document>> archiveDocument(String id, {required bool archived}) async {
    try {
      final row = await _db.from('documents')
          .update({'is_archived': archived})
          .eq('id', id)
          .select()
          .single();
      return Result.success(Mappers.documentFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<Document>> updateLastPosition(String id, {required int blockIndex}) async {
    try {
      final row = await _db.from('documents')
          .update({'last_position': blockIndex, 'last_read_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return Result.success(Mappers.documentFromRow(row));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<List<ContentBlock>>> getContent(String documentId) async {
    try {
      final row = await _db.from('documents')
          .select('content_blocks')
          .eq('id', documentId)
          .maybeSingle();
      if (row == null) return const Result.failure(NotFoundFailure());
      final jsonList = row['content_blocks'] as List? ?? [];
      return Result.success(Mappers.blocksFromJsonList(jsonList));
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<void>> cacheContent(String documentId, List<ContentBlock> blocks) async {
    try {
      final totalWords = blocks.fold(0, (sum, b) => sum + b.wordCount);
      await _db.from('documents')
          .update({
            'content_blocks': Mappers.blocksToJsonList(blocks),
            'word_count': totalWords,
          })
          .eq('id', documentId);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }
}
