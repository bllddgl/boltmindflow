import '../entities/ai_artifact.dart';
import '../repositories/ai_repository.dart';
import '../result.dart';

/// Generate or retrieve a cached quiz for a document.
class GenerateQuiz {
  GenerateQuiz(this._repo);
  final AiRepository _repo;

  Future<Result<AiArtifact>> call(String documentId, {int questionCount = 5}) {
    return _repo.generateQuiz(documentId, questionCount: questionCount);
  }
}
