import '../entities/bookmark.dart';
import '../repositories/reading_repository.dart';
import '../result.dart';

/// Add a bookmark at the current block index.
class AddBookmark {
  AddBookmark(this._repo);
  final ReadingRepository _repo;

  Future<Result<Bookmark>> call({required String documentId, required int blockIndex, String? label}) {
    return _repo.addBookmark(documentId: documentId, blockIndex: blockIndex, label: label);
  }
}
