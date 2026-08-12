import '../entities/ai_artifact.dart';
import '../repositories/ai_repository.dart';
import '../result.dart';

/// Ask a question about a document (Q&A).
class AskQuestion {
  AskQuestion(this._repo);
  final AiRepository _repo;

  Future<Result<AiArtifact>> call(String documentId, String question) {
    return _repo.askQuestion(documentId, question);
  }
}
