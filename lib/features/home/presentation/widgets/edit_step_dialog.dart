import 'package:flutter/material.dart';
import '../../../../shared/models/bot_action_step.dart';
import '../../../../shared/models/action_type.dart';

class EditStepDialog extends StatefulWidget {
  final BotActionStep step;

  const EditStepDialog({super.key, required this.step});

  @override
  State<EditStepDialog> createState() => _EditStepDialogState();
}

class _EditStepDialogState extends State<EditStepDialog> {
  late TextEditingController _minDelayController;
  late TextEditingController _maxDelayController;
  late TextEditingController _minHoldController;
  late TextEditingController _maxHoldController;
  late TextEditingController _startXController;
  late TextEditingController _startYController;
  late TextEditingController _endXController;
  late TextEditingController _endYController;
  late TextEditingController _jitterRadiusController;

  @override
  void initState() {
    super.initState();
    _minDelayController = TextEditingController(text: widget.step.minDelayMs.toString());
    _maxDelayController = TextEditingController(text: widget.step.maxDelayMs.toString());
    _minHoldController = TextEditingController(text: widget.step.minHoldTimeMs.toString());
    _maxHoldController = TextEditingController(text: widget.step.maxHoldTimeMs.toString());
    _startXController = TextEditingController(text: widget.step.startX.toString());
    _startYController = TextEditingController(text: widget.step.startY.toString());
    _endXController = TextEditingController(text: widget.step.endX?.toString() ?? '');
    _endYController = TextEditingController(text: widget.step.endY?.toString() ?? '');
    _jitterRadiusController = TextEditingController(text: widget.step.jitterRadius.toString());
  }

  @override
  void dispose() {
    _minDelayController.dispose();
    _maxDelayController.dispose();
    _minHoldController.dispose();
    _maxHoldController.dispose();
    _startXController.dispose();
    _startYController.dispose();
    _endXController.dispose();
    _endYController.dispose();
    _jitterRadiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.step.actionType.name.toUpperCase()} Step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _startXController, decoration: const InputDecoration(labelText: 'Start X'), keyboardType: TextInputType.number),
            TextField(controller: _startYController, decoration: const InputDecoration(labelText: 'Start Y'), keyboardType: TextInputType.number),
            if (widget.step.actionType == ActionType.swipe) ...[
              TextField(controller: _endXController, decoration: const InputDecoration(labelText: 'End X'), keyboardType: TextInputType.number),
              TextField(controller: _endYController, decoration: const InputDecoration(labelText: 'End Y'), keyboardType: TextInputType.number),
            ],
            TextField(controller: _minDelayController, decoration: const InputDecoration(labelText: 'Min Delay (ms)'), keyboardType: TextInputType.number),
            TextField(controller: _maxDelayController, decoration: const InputDecoration(labelText: 'Max Delay (ms)'), keyboardType: TextInputType.number),
            TextField(controller: _minHoldController, decoration: const InputDecoration(labelText: 'Min Hold Time (ms)'), keyboardType: TextInputType.number),
            TextField(controller: _maxHoldController, decoration: const InputDecoration(labelText: 'Max Hold Time (ms)'), keyboardType: TextInputType.number),
            TextField(controller: _jitterRadiusController, decoration: const InputDecoration(labelText: 'Jitter Radius'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final updatedStep = widget.step.copyWith(
              startX: double.tryParse(_startXController.text) ?? widget.step.startX,
              startY: double.tryParse(_startYController.text) ?? widget.step.startY,
              endX: widget.step.actionType == ActionType.swipe ? double.tryParse(_endXController.text) ?? widget.step.endX : widget.step.endX,
              endY: widget.step.actionType == ActionType.swipe ? double.tryParse(_endYController.text) ?? widget.step.endY : widget.step.endY,
              minDelayMs: int.tryParse(_minDelayController.text) ?? widget.step.minDelayMs,
              maxDelayMs: int.tryParse(_maxDelayController.text) ?? widget.step.maxDelayMs,
              minHoldTimeMs: int.tryParse(_minHoldController.text) ?? widget.step.minHoldTimeMs,
              maxHoldTimeMs: int.tryParse(_maxHoldController.text) ?? widget.step.maxHoldTimeMs,
              jitterRadius: double.tryParse(_jitterRadiusController.text) ?? widget.step.jitterRadius,
            );
            Navigator.pop(context, updatedStep);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
