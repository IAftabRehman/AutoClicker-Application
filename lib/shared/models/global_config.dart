import 'dart:convert';
import '../../core/constants/app_constants.dart';

class GlobalConfig {
  final int idleBreakAfterXSteps;
  final int idleBreakDurationMs;
  final int maxSequenceTimeoutMs;
  final String targetWaitText;
  final double smartBackX;
  final double smartBackY;

  const GlobalConfig({
    this.idleBreakAfterXSteps = AppConstants.defaultIdleBreakSteps,
    this.idleBreakDurationMs = AppConstants.defaultIdleBreakDurationMs,
    this.maxSequenceTimeoutMs = 60000, // Default to 60 seconds
    this.targetWaitText = "Request Cannot be Processed",
    this.smartBackX = 50.0,
    this.smartBackY = 50.0,
  });

  GlobalConfig copyWith({
    int? idleBreakAfterXSteps,
    int? idleBreakDurationMs,
    int? maxSequenceTimeoutMs,
    String? targetWaitText,
    double? smartBackX,
    double? smartBackY,
  }) {
    return GlobalConfig(
      idleBreakAfterXSteps: idleBreakAfterXSteps ?? this.idleBreakAfterXSteps,
      idleBreakDurationMs: idleBreakDurationMs ?? this.idleBreakDurationMs,
      maxSequenceTimeoutMs: maxSequenceTimeoutMs ?? this.maxSequenceTimeoutMs,
      targetWaitText: targetWaitText ?? this.targetWaitText,
      smartBackX: smartBackX ?? this.smartBackX,
      smartBackY: smartBackY ?? this.smartBackY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idleBreakAfterXSteps': idleBreakAfterXSteps,
      'idleBreakDurationMs': idleBreakDurationMs,
      'maxSequenceTimeoutMs': maxSequenceTimeoutMs,
      'targetWaitText': targetWaitText,
      'smartBackX': smartBackX,
      'smartBackY': smartBackY,
    };
  }

  factory GlobalConfig.fromMap(Map<String, dynamic> map) {
    return GlobalConfig(
      idleBreakAfterXSteps: map['idleBreakAfterXSteps']?.toInt() ?? AppConstants.defaultIdleBreakSteps,
      idleBreakDurationMs: map['idleBreakDurationMs']?.toInt() ?? AppConstants.defaultIdleBreakDurationMs,
      maxSequenceTimeoutMs: map['maxSequenceTimeoutMs']?.toInt() ?? 60000,
      targetWaitText: map['targetWaitText'] ?? "Request Cannot be Processed",
      smartBackX: (map['smartBackX'] as num?)?.toDouble() ?? 50.0,
      smartBackY: (map['smartBackY'] as num?)?.toDouble() ?? 50.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory GlobalConfig.fromJson(String source) => GlobalConfig.fromMap(json.decode(source));
}
