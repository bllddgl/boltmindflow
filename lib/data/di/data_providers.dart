import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/usecases/add_bookmark.dart';
import '../../domain/usecases/ask_question.dart';
import '../../domain/usecases/end_reading.dart';
import '../../domain/usecases/generate_quiz.dart';
import '../../domain/usecases/generate_summary.dart';
import '../../domain/usecases/get_due_cards.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/get_stats.dart';
import '../../domain/usecases/grade_card.dart';
import '../../domain/usecases/import_document.dart';
import '../../domain/usecases/load_document.dart';
import '../../domain/usecases/save_position.dart';
import '../../domain/usecases/save_settings.dart';
import '../../domain/usecases/start_reading.dart';
import '../parsers/epub_parser.dart';
import '../parsers/parser_registry.dart';
import '../parsers/pdf_parser.dart';
import '../parsers/txt_parser.dart';
import '../repositories/supabase_ai_repository.dart';
import '../repositories/supabase_document_repository.dart';
import '../repositories/supabase_reading_repository.dart';
import '../repositories/supabase_review_repository.dart';
import '../repositories/supabase_settings_repository.dart';
import '../repositories/supabase_stats_repository.dart';

// =============================================================================
// Repository providers — the single seam where implementations are wired.
// Swap any of these to change the data source (e.g. remote AI, cloud sync).
// =============================================================================

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return SupabaseDocumentRepository();
});

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return SupabaseReadingRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository();
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return SupabaseStatsRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SupabaseSettingsRepository();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return SupabaseAiRepository();
});

// =============================================================================
// Parser registry — the seam where document parsers are wired.
// =============================================================================

final parserRegistryProvider = Provider<ParserRegistry>((ref) {
  final registry = ParserRegistry._();
  registry.register(TxtParser());
  registry.register(EpubParser());
  registry.register(PdfParser());
  return registry;
});

// =============================================================================
// Use case providers
// =============================================================================

final importDocumentProvider = Provider<ImportDocument>((ref) {
  return ImportDocument(ref.watch(documentRepositoryProvider));
});

final loadDocumentProvider = Provider<LoadDocument>((ref) {
  return LoadDocument(ref.watch(documentRepositoryProvider));
});

final savePositionProvider = Provider<SavePosition>((ref) {
  return SavePosition(ref.watch(documentRepositoryProvider));
});

final addBookmarkProvider = Provider<AddBookmark>((ref) {
  return AddBookmark(ref.watch(readingRepositoryProvider));
});

final startReadingProvider = Provider<StartReading>((ref) {
  return StartReading(ref.watch(readingRepositoryProvider));
});

final endReadingProvider = Provider<EndReading>((ref) {
  return EndReading(ref.watch(readingRepositoryProvider));
});

final getDueCardsProvider = Provider<GetDueCards>((ref) {
  return GetDueCards(ref.watch(reviewRepositoryProvider));
});

final gradeCardProvider = Provider<GradeCard>((ref) {
  return GradeCard(ref.watch(reviewRepositoryProvider));
});

final getStatsProvider = Provider<GetStats>((ref) {
  return GetStats(ref.watch(statsRepositoryProvider));
});

final generateSummaryProvider = Provider<GenerateSummary>((ref) {
  return GenerateSummary(ref.watch(aiRepositoryProvider));
});

final generateQuizProvider = Provider<GenerateQuiz>((ref) {
  return GenerateQuiz(ref.watch(aiRepositoryProvider));
});

final askQuestionProvider = Provider<AskQuestion>((ref) {
  return AskQuestion(ref.watch(aiRepositoryProvider));
});

final getSettingsProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final saveSettingsProvider = Provider<SaveSettings>((ref) {
  return SaveSettings(ref.watch(settingsRepositoryProvider));
});
