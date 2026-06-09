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
import '../../simulator/presentation/tamm_simulator_screen.dart';
import '../../../core/native_bridge/native_bridge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool isRunning = false;

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
            const SizedBox(height: 16),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Smart Automation Flow', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: ref.read(globalConfigProvider).targetWaitText,
                      decoration: const InputDecoration(
                        labelText: 'Smart Wait Text (Condition)',
                        hintText: 'Text to scan for before retrying',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: (val) {
                        final current = ref.read(globalConfigProvider);
                        ref.read(globalConfigProvider.notifier).updateConfig(current.copyWith(targetWaitText: val));
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: ref.read(globalConfigProvider).smartBackX.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Smart Back X',
                              labelStyle: TextStyle(color: AppColors.textSecondary),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final current = ref.read(globalConfigProvider);
                              ref.read(globalConfigProvider.notifier).updateConfig(current.copyWith(smartBackX: double.tryParse(val) ?? 50.0));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: ref.read(globalConfigProvider).smartBackY.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Smart Back Y',
                              labelStyle: TextStyle(color: AppColors.textSecondary),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final current = ref.read(globalConfigProvider);
                              ref.read(globalConfigProvider.notifier).updateConfig(current.copyWith(smartBackY: double.tryParse(val) ?? 50.0));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                        
                        await NativeBridge().startAutomationSequence(
                          botSequence,
                          globalConfig,
                        );
                        
                        await NativeBridge().startOverlay();
                        
                        setState(() {
                          isRunning = true;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Open TAMM Simulator (Test Mode)',
              color: AppColors.surface,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TammSimulatorScreen()),
                );
              },
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
