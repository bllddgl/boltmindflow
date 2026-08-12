import '../entities/ai_artifact.dart';
import '../repositories/ai_repository.dart';
import '../result.dart';

/// Generate or retrieve a cached summary for a document.
class GenerateSummary {
  GenerateSummary(this._repo);
  final AiRepository _repo;

  Future<Result<AiArtifact>> call(String documentId) {
    return _repo.generateSummary(documentId);
  }
}
