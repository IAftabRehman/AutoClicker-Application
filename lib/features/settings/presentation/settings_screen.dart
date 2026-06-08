import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/setting_slider.dart';
import '../providers/global_config_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(globalConfigProvider);
    final configNotifier = ref.read(globalConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Bot Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingSlider(
            title: 'Minimum Delay',
            value: 800,
            min: 100,
            max: 2000,
            unit: 'ms',
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),
          SettingSlider(
            title: 'Maximum Delay',
            value: 1500,
            min: 100,
            max: 2000,
            unit: 'ms',
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),
          SettingSlider(
            title: 'Touch Jitter Radius',
            value: 15,
            min: 0,
            max: 50,
            unit: 'px',
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),
          SettingSlider(
            title: 'Pause After X Steps',
            value: config.idleBreakAfterXSteps.toDouble(),
            min: 5,
            max: 50,
            unit: 'steps',
            onChanged: (val) {
              configNotifier.updateConfig(config.copyWith(idleBreakAfterXSteps: val.toInt()));
            },
          ),
          const SizedBox(height: 24),
          SettingSlider(
            title: 'Pause Duration',
            value: config.idleBreakDurationMs.toDouble(),
            min: 1000,
            max: 10000,
            unit: 'ms',
            onChanged: (val) {
              configNotifier.updateConfig(config.copyWith(idleBreakDurationMs: val.toInt()));
            },
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Save Settings',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
