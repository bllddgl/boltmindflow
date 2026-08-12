import '../entities/user_settings.dart';
import '../result.dart';

/// Abstract interface for user settings (theme, WPM, language, etc.).
///
/// Backed by Hive (key-value) — settings are read on every screen frame, so a
/// binary KV store is faster than SQLite for this shape.
abstract class SettingsRepository {
  Future<Result<UserSettings>> getSettings();
  Future<Result<void>> saveSettings(UserSettings settings);
  Future<Result<bool>> getHasOnboarded();
  Future<Result<void>> setHasOnboarded(bool value);
}
