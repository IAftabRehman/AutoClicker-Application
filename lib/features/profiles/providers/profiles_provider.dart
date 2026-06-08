import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/bot_profile.dart';
import '../data/profiles_storage_service.dart';
import '../../../shared/local_storage/storage_provider.dart';
import '../../../shared/models/bot_action_step.dart';
import '../../../shared/models/global_config.dart';
import '../../home/providers/bot_sequence_provider.dart';
import '../../settings/providers/global_config_provider.dart';

final profilesStorageServiceProvider = Provider<ProfilesStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfilesStorageService(prefs);
});

class ProfilesNotifier extends Notifier<List<BotProfile>> {
  late final ProfilesStorageService _storageService;

  @override
  List<BotProfile> build() {
    _storageService = ref.watch(profilesStorageServiceProvider);
    return _storageService.getProfiles();
  }

  Future<void> saveNewProfile(String name, List<BotActionStep> steps, GlobalConfig config) async {
    final newProfile = BotProfile(
      id: const Uuid().v4(),
      profileName: name,
      steps: steps,
      config: config,
    );
    await _storageService.saveProfile(newProfile);
    state = _storageService.getProfiles();
  }

  Future<void> deleteProfile(String id) async {
    await _storageService.deleteProfile(id);
    state = _storageService.getProfiles();
  }

  void loadProfileIntoActiveState(String id) {
    final profile = state.firstWhere((p) => p.id == id);
    ref.read(botSequenceProvider.notifier).loadSequence(profile.steps);
    ref.read(globalConfigProvider.notifier).updateConfig(profile.config);
  }
}

final profilesProvider = NotifierProvider<ProfilesNotifier, List<BotProfile>>(
  ProfilesNotifier.new,
);
