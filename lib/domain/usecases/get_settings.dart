import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';
import '../result.dart';

/// Load persisted user settings.
class GetSettings {
  GetSettings(this._repo);
  final SettingsRepository _repo;

  Future<Result<UserSettings>> call() => _repo.getSettings();
}
