import '../entities/content_block.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../result.dart';

/// Import a document file: copy to app docs dir, parse via the registry,
/// store metadata, cache blocks.
///
/// The use case orchestrates the repository; the parser registry is injected
/// via the repository implementation, not here — this keeps the use case
/// format-agnostic.
class ImportDocument {
  ImportDocument(this._repo);
  final DocumentRepository _repo;

  Future<Result<Document>> call({
    required String filePath,
    required String title,
    String? author,
    required String format,
  }) {
    return _repo.importDocument(
      filePath: filePath,
      title: title,
      author: author,
      format: format,
    );
  }
}
