import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';
import '../result.dart';

/// Save user settings (theme, WPM, language, etc.).
class SaveSettings {
  SaveSettings(this._repo);
  final SettingsRepository _repo;

  Future<Result<void>> call(UserSettings settings) => _repo.saveSettings(settings);
}
