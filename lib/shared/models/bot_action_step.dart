import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import 'action_type.dart';

class BotActionStep {
  final String id;
  final ActionType actionType;
  final double startX;
  final double startY;
  final double? endX;
  final double? endY;
  final int minDelayMs;
  final int maxDelayMs;
  final int minHoldTimeMs;
  final int maxHoldTimeMs;
  final double jitterRadius;
  final bool isCurvedSwipe;
  final String? waitForText;
  final int stepTimeoutMs;

  BotActionStep({
    String? id,
    required this.actionType,
    required this.startX,
    required this.startY,
    this.endX,
    this.endY,
    this.minDelayMs = AppConstants.defaultMinDelayMs,
    this.maxDelayMs = AppConstants.defaultMaxDelayMs,
    this.minHoldTimeMs = AppConstants.defaultMinHoldTimeMs,
    this.maxHoldTimeMs = AppConstants.defaultMaxHoldTimeMs,
    this.jitterRadius = AppConstants.defaultJitterRadius,
    this.isCurvedSwipe = false,
    this.waitForText,
    this.stepTimeoutMs = 10000, // Default to 10 seconds
  }) : id = id ?? const Uuid().v4();

  BotActionStep copyWith({
    String? id,
    ActionType? actionType,
    double? startX,
    double? startY,
    double? endX,
    double? endY,
    int? minDelayMs,
    int? maxDelayMs,
    int? minHoldTimeMs,
    int? maxHoldTimeMs,
    double? jitterRadius,
    bool? isCurvedSwipe,
    String? waitForText,
    int? stepTimeoutMs,
  }) {
    return BotActionStep(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      startX: startX ?? this.startX,
      startY: startY ?? this.startY,
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      minDelayMs: minDelayMs ?? this.minDelayMs,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      minHoldTimeMs: minHoldTimeMs ?? this.minHoldTimeMs,
      maxHoldTimeMs: maxHoldTimeMs ?? this.maxHoldTimeMs,
      jitterRadius: jitterRadius ?? this.jitterRadius,
      isCurvedSwipe: isCurvedSwipe ?? this.isCurvedSwipe,
      waitForText: waitForText ?? this.waitForText,
      stepTimeoutMs: stepTimeoutMs ?? this.stepTimeoutMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType.name,
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
      'minDelayMs': minDelayMs,
      'maxDelayMs': maxDelayMs,
      'minHoldTimeMs': minHoldTimeMs,
      'maxHoldTimeMs': maxHoldTimeMs,
      'jitterRadius': jitterRadius,
      'isCurvedSwipe': isCurvedSwipe,
      'waitForText': waitForText,
      'stepTimeoutMs': stepTimeoutMs,
    };
  }

  factory BotActionStep.fromMap(Map<String, dynamic> map) {
    return BotActionStep(
      id: map['id'],
      actionType: ActionType.values.firstWhere((e) => e.name == map['actionType'], orElse: () => ActionType.tap),
      startX: map['startX']?.toDouble() ?? 0.0,
      startY: map['startY']?.toDouble() ?? 0.0,
      endX: map['endX']?.toDouble(),
      endY: map['endY']?.toDouble(),
      minDelayMs: map['minDelayMs']?.toInt() ?? AppConstants.defaultMinDelayMs,
      maxDelayMs: map['maxDelayMs']?.toInt() ?? AppConstants.defaultMaxDelayMs,
      minHoldTimeMs: map['minHoldTimeMs']?.toInt() ?? AppConstants.defaultMinHoldTimeMs,
      maxHoldTimeMs: map['maxHoldTimeMs']?.toInt() ?? AppConstants.defaultMaxHoldTimeMs,
      jitterRadius: map['jitterRadius']?.toDouble() ?? AppConstants.defaultJitterRadius,
      isCurvedSwipe: map['isCurvedSwipe'] ?? false,
      waitForText: map['waitForText'],
      stepTimeoutMs: map['stepTimeoutMs']?.toInt() ?? 10000,
    );
  }
}
