import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/bot_action_step.dart';
import '../../../../shared/models/action_type.dart';

class ActionStepCard extends StatelessWidget {
  final BotActionStep step;
  final VoidCallback onDelete;

  const ActionStepCard({
    super.key,
    required this.step,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTap = step.actionType == ActionType.tap;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTap ? Icons.touch_app : Icons.swipe,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        title: Text(
          'Action: ${step.actionType.name.toUpperCase()}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Target: X:${step.startX.toStringAsFixed(0)}, Y:${step.startY.toStringAsFixed(0)}\nDelay: ${step.minDelayMs}ms - ${step.maxDelayMs}ms',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
