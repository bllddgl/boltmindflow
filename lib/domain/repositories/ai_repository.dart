import '../entities/ai_artifact.dart';
import '../result.dart';

/// Abstract interface for AI features (the "online plane").
///
/// Implementations:
/// - [OfflineAiRepository] — returns [Failure.offline] for gated calls when
///   offline or free-tier (summary limited to 3/day).
/// - [RemoteAiRepository] — premium + online; calls a backend LLM.
/// - [FakeAiRepository] — tests.
///
/// The DI composition root picks the impl based on feature flags + connectivity.
abstract class AiRepository {
  Future<Result<AiArtifact>> generateSummary(String documentId);
  Future<Result<AiArtifact>> generateQuiz(String documentId, {int questionCount = 5});
  Future<Result<AiArtifact>> askQuestion(String documentId, String question);
  Future<Result<List<AiArtifact>>> getCachedArtifacts(String documentId);
  Future<Result<AiArtifact>> generateWeeklyInsight(String userId);
}
