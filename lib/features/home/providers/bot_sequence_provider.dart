import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/bot_action_step.dart';

class BotSequenceNotifier extends Notifier<List<BotActionStep>> {
  @override
  List<BotActionStep> build() => [];

  void addStep(BotActionStep step) {
    state = [...state, step];
  }

  void removeStep(String id) {
    state = state.where((step) => step.id != id).toList();
  }

  void updateStep(BotActionStep updatedStep) {
    state = [
      for (final step in state)
        if (step.id == updatedStep.id) updatedStep else step,
    ];
  }

  void loadSequence(List<BotActionStep> steps) {
    state = steps;
  }

  void reorderSteps(int oldIndex, int newIndex) {
    final newList = List.of(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final step = newList.removeAt(oldIndex);
    newList.insert(newIndex, step);
    state = newList;
  }
}

final botSequenceProvider = NotifierProvider<BotSequenceNotifier, List<BotActionStep>>(
  BotSequenceNotifier.new,
);
