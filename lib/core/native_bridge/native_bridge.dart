import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../../../shared/models/bot_action_step.dart';
import '../../../shared/models/global_config.dart';

class NativeBridge {
  static final NativeBridge _instance = NativeBridge._internal();
  factory NativeBridge() => _instance;

  final StreamController<List<Map<String, dynamic>>> _targetsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get targetsStream => _targetsStreamController.stream;

  NativeBridge._internal() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static const MethodChannel _channel = MethodChannel('com.autobot.app/bridge');

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    if (call.method == 'onTargetsSaved') {
      final List<dynamic> args = call.arguments;
      final List<Map<String, dynamic>> coordinates = args.map((e) => Map<String, dynamic>.from(e)).toList();
      _targetsStreamController.add(coordinates);
    }
  }

  Future<Map<String, bool>> checkPermissions() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('checkPermissions');
      if (result != null) {
        return {
          'overlay': result['overlay'] == true,
          'accessibility': result['accessibility'] == true,
        };
      }
    } catch (e) {
      // Fallback on error
    }
    return {'overlay': false, 'accessibility': false};
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      // Ignored for now
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      // Ignored for now
    }
  }
  
  Future<void> startOverlay() async {
    try {
      await _channel.invokeMethod('startOverlay');
    } catch (e) {
      // Ignored
    }
  }

  Future<void> stopOverlay() async {
    try {
      await _channel.invokeMethod('stopOverlay');
    } catch (e) {
      // Ignored
    }
  }

  Future<void> startAutomationSequence(List<BotActionStep> steps, GlobalConfig config, {Uint8List? conditionImage}) async {
    try {
      final List<Map<String, dynamic>> serializedSteps = steps.map((s) => s.toMap()).toList();
      final Map<String, dynamic> serializedConfig = config.toMap();
      await _channel.invokeMethod('startAutomation', {
        'steps': serializedSteps,
        'config': serializedConfig,
        'conditionImage': conditionImage,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> stopAutomationSequence() async {
    try {
      await _channel.invokeMethod('stopAutomation');
    } catch (e) {
      // Ignored
    }
  }

  Future<void> requestScreenCapture() async {
    try {
      await _channel.invokeMethod('requestScreenCapture');
    } catch (e) {
      // Ignored
    }
  }
}
