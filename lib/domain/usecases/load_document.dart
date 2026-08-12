import '../entities/content_block.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../result.dart';

/// Load a document and its parsed content blocks for reading.
class LoadDocument {
  LoadDocument(this._repo);
  final DocumentRepository _repo;

  Future<Result<({Document document, List<ContentBlock> blocks})>> call(String documentId) async {
    final docResult = await _repo.getById(documentId);
    return docResult.when(
      success: (doc) async {
        final contentResult = await _repo.getContent(documentId);
        return contentResult.when(
          success: (blocks) => Result.success((document: doc, blocks: blocks)),
          failure: Result.failure,
        );
      },
      failure: Result.failure,
    );
  }
}
