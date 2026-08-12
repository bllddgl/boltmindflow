import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/ai_artifact.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/result.dart';
import '../mappers.dart';
import '../supabase_client.dart';

/// Offline / cached AI repository.
///
/// Phase 1: returns cached artifacts if they exist, otherwise returns a
/// [PremiumRequiredFailure] or [AiFailure]. The real LLM call will be wired
/// through an edge function in Module 11.
class SupabaseAiRepository implements AiRepository {
  SupabaseAiRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<AiArtifact>> generateSummary(String documentId) async {
    try {
      final row = await _db.from('ai_artifacts')
          .select()
          .eq('document_id', documentId)
          .eq('artifact_type', 'summary')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return const Result.failure(AiFailure('No cached summary. Connect to generate.'));
      return Result.success(Mappers.aiArtifactFromRow(row));
    } catch (e) {
      return const Result.failure(AiFailure());
    }
  }

  @override
  Future<Result<AiArtifact>> generateQuiz(String documentId, {int questionCount = 5}) async {
    try {
      final row = await _db.from('ai_artifacts')
          .select()
          .eq('document_id', documentId)
          .eq('artifact_type', 'quiz')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return const Result.failure(AiFailure('No cached quiz. Connect to generate.'));
      return Result.success(Mappers.aiArtifactFromRow(row));
    } catch (e) {
      return const Result.failure(AiFailure());
    }
  }

  @override
  Future<Result<AiArtifact>> askQuestion(String documentId, String question) async {
    return const Result.failure(AiFailure('Q&A requires an online connection.'));
  }

  @override
  Future<Result<List<AiArtifact>>> getCachedArtifacts(String documentId) async {
    try {
      final rows = await _db.from('ai_artifacts')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: false);
      return Result.success(rows.map(Mappers.aiArtifactFromRow).toList());
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<AiArtifact>> generateWeeklyInsight(String userId) async {
    try {
      final row = await _db.from('ai_artifacts')
          .select()
          .eq('artifact_type', 'insight')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return const Result.failure(AiFailure('No insight available.'));
      return Result.success(Mappers.aiArtifactFromRow(row));
    } catch (e) {
      return const Result.failure(AiFailure());
    }
  }
}
