import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/result.dart';
import '../mappers.dart';
import '../supabase_client.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository();

  SupabaseClient get _db => SupabaseClientWrapper.instance.client;

  @override
  Future<Result<UserSettings>> getSettings() async {
    try {
      final row = await _db.from('user_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return Result.success(UserSettings.defaults());
      return Result.success(Mappers.settingsFromRow(row));
    } catch (e) {
      return Result.success(UserSettings.defaults());
    }
  }

  @override
  Future<Result<void>> saveSettings(UserSettings settings) async {
    try {
      await _db.from('user_settings').upsert({
        'id': 1,
        'theme_mode': settings.themeMode,
        'locale': settings.locale,
        'font_scale': settings.fontScale,
        'target_wpm': settings.rsvp.targetWpm,
        'words_per_display': settings.rsvp.wordsPerDisplay,
        'line_count': settings.rsvp.lineCount,
        'image_duration_ms': settings.rsvp.imageDuration.inMilliseconds,
        'adaptive_speed': settings.rsvp.adaptiveSpeed,
      });
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }

  @override
  Future<Result<bool>> getHasOnboarded() async {
    try {
      final row = await _db.from('user_settings')
          .select('has_onboarded')
          .eq('id', 1)
          .maybeSingle();
      return Result.success(row?['has_onboarded'] as bool? ?? false);
    } catch (e) {
      return const Result.success(false);
    }
  }

  @override
  Future<Result<void>> setHasOnboarded(bool value) async {
    try {
      await _db.from('user_settings').upsert({
        'id': 1,
        'has_onboarded': value,
      });
      return const Result.success(null);
    } catch (e) {
      return const Result.failure(StorageFailure());
    }
  }
}
