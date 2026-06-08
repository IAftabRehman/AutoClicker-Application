import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/global_config.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveGlobalConfig(GlobalConfig config) async {
    await _prefs.setString(AppConstants.prefsConfigKey, config.toJson());
  }

  GlobalConfig? getGlobalConfig() {
    final String? configJson = _prefs.getString(AppConstants.prefsConfigKey);
    if (configJson != null) {
      try {
        return GlobalConfig.fromJson(configJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
