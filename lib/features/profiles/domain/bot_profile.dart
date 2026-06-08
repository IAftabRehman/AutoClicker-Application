import 'dart:convert';
import '../../../shared/models/bot_action_step.dart';
import '../../../shared/models/global_config.dart';

class BotProfile {
  final String id;
  final String profileName;
  final List<BotActionStep> steps;
  final GlobalConfig config;

  BotProfile({
    required this.id,
    required this.profileName,
    required this.steps,
    required this.config,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileName': profileName,
      'steps': steps.map((x) => x.toMap()).toList(),
      'config': config.toMap(),
    };
  }

  factory BotProfile.fromMap(Map<String, dynamic> map) {
    return BotProfile(
      id: map['id'] ?? '',
      profileName: map['profileName'] ?? '',
      steps: List<BotActionStep>.from(map['steps']?.map((x) => BotActionStep.fromMap(x)) ?? []),
      config: GlobalConfig.fromMap(map['config'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory BotProfile.fromJson(String source) => BotProfile.fromMap(json.decode(source));
}
