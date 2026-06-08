import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native_bridge/native_bridge.dart';

class PermissionsNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {'overlay': false, 'accessibility': false};
  }

  Future<void> refreshPermissions() async {
    final newPermissions = await NativeBridge().checkPermissions();
    state = newPermissions;
  }
}

final permissionsProvider = NotifierProvider<PermissionsNotifier, Map<String, bool>>(
  PermissionsNotifier.new,
);
