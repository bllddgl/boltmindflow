import '../repositories/document_repository.dart';
import '../result.dart';

/// Save the current reading position (block index) for "continue reading".
class SavePosition {
  SavePosition(this._repo);
  final DocumentRepository _repo;

  Future<Result<void>> call(String documentId, int blockIndex) {
    return _repo.updateLastPosition(documentId, blockIndex: blockIndex);
  }
}
