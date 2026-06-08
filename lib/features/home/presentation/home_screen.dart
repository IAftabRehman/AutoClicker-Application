import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_card.dart';
import '../../settings/presentation/settings_screen.dart';
import '../providers/bot_sequence_provider.dart';
import '../../../shared/models/bot_action_step.dart';
import '../../../shared/models/action_type.dart';
import 'widgets/action_step_card.dart';
import 'widgets/edit_step_dialog.dart';
import '../../bot_runner/presentation/permissions_card.dart';
import '../../bot_runner/providers/permissions_provider.dart';
import '../../settings/providers/global_config_provider.dart';
import '../../testing/presentation/test_playground_screen.dart';
import '../../../core/native_bridge/native_bridge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool isRunning = false;
  XFile? _conditionImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(permissionsProvider.notifier).refreshPermissions(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsProvider.notifier).refreshPermissions();
    }
  }

  void _showActionSelectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.touch_app, color: AppColors.primary),
                title: const Text(
                  'Add Tap',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(botSequenceProvider.notifier)
                      .addStep(
                        BotActionStep(
                          actionType: ActionType.tap,
                          startX: 100.0,
                          startY: 200.0,
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.swipe, color: AppColors.primary),
                title: const Text(
                  'Add Swipe',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(botSequenceProvider.notifier)
                      .addStep(
                        BotActionStep(
                          actionType: ActionType.swipe,
                          startX: 100.0,
                          startY: 200.0,
                          endX: 100.0,
                          endY: 500.0,
                        ),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickConditionImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _conditionImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final botSequence = ref.watch(botSequenceProvider);
    final permissions = ref.watch(permissionsProvider);
    final canStart =
        (permissions['overlay'] == true) &&
        (permissions['accessibility'] == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Dashboard'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestPlaygroundScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const PermissionsStatusCard(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface),
                ),
                child: botSequence.isEmpty
                    ? const Center(
                        child: Text(
                          'No Action Steps Added Yet.\nTap + to add.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: botSequence.length,
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(botSequenceProvider.notifier)
                              .reorderSteps(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final step = botSequence[index];
                          return InkWell(
                            key: ValueKey(step.id),
                            onTap: () async {
                              final updatedStep =
                                  await showDialog<BotActionStep>(
                                    context: context,
                                    builder: (context) =>
                                        EditStepDialog(step: step),
                                  );
                              if (updatedStep != null) {
                                ref
                                    .read(botSequenceProvider.notifier)
                                    .updateStep(updatedStep);
                              }
                            },
                            child: ActionStepCard(
                              step: step,
                              onDelete: () {
                                ref
                                    .read(botSequenceProvider.notifier)
                                    .removeStep(step.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickConditionImage,
                    icon: const Icon(Icons.image),
                    label: Text(_conditionImage == null ? 'Select Condition Image' : 'Change Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_conditionImage != null) ...[
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                          image: DecorationImage(
                            image: FileImage(File(_conditionImage!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _conditionImage = null),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: isRunning ? 'Stop & Hide Overlay' : 'Show Overlay',
              color: isRunning ? AppColors.error : AppColors.primary,
              onPressed: canStart
                  ? () async {
                      if (isRunning) {
                        await NativeBridge().stopAutomationSequence();
                        await NativeBridge().stopOverlay();
                        setState(() {
                          isRunning = false;
                        });
                      } else {
                        await NativeBridge().requestScreenCapture();
                        // We add a brief 500ms delay to allow the Android permission dialog to slide up
                        await Future.delayed(const Duration(milliseconds: 500));
                        final globalConfig = ref.read(globalConfigProvider);
                        final imageBytes = _conditionImage != null ? await _conditionImage!.readAsBytes() : null;
                        
                        await NativeBridge().startAutomationSequence(
                          botSequence,
                          globalConfig,
                          conditionImage: imageBytes,
                        );
                        
                        await NativeBridge().startOverlay();
                        
                        setState(() {
                          isRunning = true;
                        });
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSelectionMenu(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }
}
