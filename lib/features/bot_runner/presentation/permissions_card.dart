import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider.dart';
import '../../../core/native_bridge/native_bridge.dart';

class PermissionsStatusCard extends ConsumerWidget {
  const PermissionsStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final bool hasOverlay = permissions['overlay'] ?? false;
    final bool hasAccessibility = permissions['accessibility'] ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPermissionRow(
              title: 'Overlay Permission',
              isGranted: hasOverlay,
              onRequest: () async {
                await NativeBridge().requestOverlayPermission();
                await ref.read(permissionsProvider.notifier).refreshPermissions();
              },
            ),
            const Divider(),
            _buildPermissionRow(
              title: 'Accessibility Service',
              isGranted: hasAccessibility,
              onRequest: () async {
                await NativeBridge().requestAccessibilityPermission();
                await ref.read(permissionsProvider.notifier).refreshPermissions();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required String title,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (isGranted)
          const Icon(Icons.check_circle, color: Colors.green)
        else
          TextButton(
            onPressed: onRequest,
            child: const Text('Grant'),
          ),
      ],
    );
  }
}
