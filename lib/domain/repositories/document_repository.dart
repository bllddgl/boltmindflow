import '../entities/content_block.dart';
import '../entities/document.dart';
import '../result.dart';

/// Abstract interface for document storage and content access.
///
/// Implemented by [SqliteDocumentRepository] (data layer). The interface lives
/// in domain so data depends on domain, not vice versa. Swapping SQLite for
/// Supabase later = a new implementation + one provider override.
abstract class DocumentRepository {
  Future<Result<List<Document>>> getAll({bool includeArchived = false});
  Future<Result<Document>> getById(String id);
  Future<Result<Document>> importDocument({
    required String filePath,
    required String title,
    String? author,
    required String format,
  });
  Future<Result<void>> deleteDocument(String id);
  Future<Result<Document>> archiveDocument(String id, {required bool archived});
  Future<Result<Document>> updateLastPosition(String id, {required int blockIndex});
  Future<Result<List<ContentBlock>>> getContent(String documentId);
  Future<Result<void>> cacheContent(String documentId, List<ContentBlock> blocks);
}
