import '../entities/bookmark.dart';
import '../entities/reading_session.dart';
import '../result.dart';

/// Abstract interface for reading sessions and bookmarks.
abstract class ReadingRepository {
  // Sessions
  Future<Result<ReadingSession>> startSession(String documentId);
  Future<Result<ReadingSession>> endSession(String sessionId, {required int wordsRead, required int blocksRead, required int avgWpm, required double focusScore});
  Future<Result<List<ReadingSession>>> getSessionsForDocument(String documentId);
  Future<Result<ReadingSession?>> getLastSession(String documentId);

  // Bookmarks
  Future<Result<Bookmark>> addBookmark({required String documentId, required int blockIndex, String? label});
  Future<Result<void>> removeBookmark(String bookmarkId);
  Future<Result<List<Bookmark>>> getBookmarks(String documentId);
}
