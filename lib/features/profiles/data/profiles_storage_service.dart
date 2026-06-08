import 'package:shared_preferences/shared_preferences.dart';
import '../domain/bot_profile.dart';

class ProfilesStorageService {
  static const String _profilesKey = 'bot_profiles';
  final SharedPreferences _prefs;

  ProfilesStorageService(this._prefs);

  Future<void> saveProfile(BotProfile profile) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await _prefs.setStringList(_profilesKey, jsonList);
  }

  List<BotProfile> getProfiles() {
    final jsonList = _prefs.getStringList(_profilesKey) ?? [];
    return jsonList.map((jsonStr) => BotProfile.fromJson(jsonStr)).toList();
  }

  Future<void> deleteProfile(String id) async {
    final profiles = getProfiles();
    profiles.removeWhere((p) => p.id == id);
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await _prefs.setStringList(_profilesKey, jsonList);
  }
}
