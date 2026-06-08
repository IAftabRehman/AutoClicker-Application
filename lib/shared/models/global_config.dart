import 'dart:convert';
import '../../core/constants/app_constants.dart';

class GlobalConfig {
  final int idleBreakAfterXSteps;
  final int idleBreakDurationMs;
  final int maxSequenceTimeoutMs;

  const GlobalConfig({
    this.idleBreakAfterXSteps = AppConstants.defaultIdleBreakSteps,
    this.idleBreakDurationMs = AppConstants.defaultIdleBreakDurationMs,
    this.maxSequenceTimeoutMs = 60000, // Default to 60 seconds
  });

  GlobalConfig copyWith({
    int? idleBreakAfterXSteps,
    int? idleBreakDurationMs,
    int? maxSequenceTimeoutMs,
  }) {
    return GlobalConfig(
      idleBreakAfterXSteps: idleBreakAfterXSteps ?? this.idleBreakAfterXSteps,
      idleBreakDurationMs: idleBreakDurationMs ?? this.idleBreakDurationMs,
      maxSequenceTimeoutMs: maxSequenceTimeoutMs ?? this.maxSequenceTimeoutMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idleBreakAfterXSteps': idleBreakAfterXSteps,
      'idleBreakDurationMs': idleBreakDurationMs,
      'maxSequenceTimeoutMs': maxSequenceTimeoutMs,
    };
  }

  factory GlobalConfig.fromMap(Map<String, dynamic> map) {
    return GlobalConfig(
      idleBreakAfterXSteps: map['idleBreakAfterXSteps']?.toInt() ?? AppConstants.defaultIdleBreakSteps,
      idleBreakDurationMs: map['idleBreakDurationMs']?.toInt() ?? AppConstants.defaultIdleBreakDurationMs,
      maxSequenceTimeoutMs: map['maxSequenceTimeoutMs']?.toInt() ?? 60000,
    );
  }

  String toJson() => json.encode(toMap());

  factory GlobalConfig.fromJson(String source) => GlobalConfig.fromMap(json.decode(source));
}
