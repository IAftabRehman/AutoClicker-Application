import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/local_storage/local_storage_service.dart';
import '../../../shared/local_storage/storage_provider.dart';
import '../../../shared/models/global_config.dart';

class GlobalConfigNotifier extends Notifier<GlobalConfig> {
  late final LocalStorageService _localStorageService;

  @override
  GlobalConfig build() {
    _localStorageService = ref.watch(localStorageServiceProvider);
    return _localStorageService.getGlobalConfig() ?? const GlobalConfig();
  }

  Future<void> updateConfig(GlobalConfig newConfig) async {
    state = newConfig;
    await _localStorageService.saveGlobalConfig(newConfig);
  }
}

final globalConfigProvider = NotifierProvider<GlobalConfigNotifier, GlobalConfig>(
  GlobalConfigNotifier.new,
);
