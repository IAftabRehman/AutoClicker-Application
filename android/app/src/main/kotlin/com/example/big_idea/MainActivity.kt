package com.example.big_idea

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.autobot.app/bridge"
    private lateinit var methodChannel: MethodChannel

    private val targetReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.autobot.app.TARGETS_SAVED") {
                val coordinates = intent.getSerializableExtra("coordinates") as? ArrayList<HashMap<String, Int>>
                if (coordinates != null) {
                    methodChannel.invokeMethod("onTargetsSaved", coordinates)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter("com.autobot.app.TARGETS_SAVED")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(targetReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(targetReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(targetReceiver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val overlay = Settings.canDrawOverlays(this)
                    val accessibility = isAccessibilityServiceEnabled()
                    val map = mapOf("overlay" to overlay, "accessibility" to accessibility)
                    result.success(map)
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                    startActivity(intent)
                    result.success(null)
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "startOverlay" -> {
                    if (Settings.canDrawOverlays(this)) {
                        val intent = Intent(this, FloatingOverlayService::class.java)
                        startService(intent)
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                    }
                }
                "stopOverlay" -> {
                    val intent = Intent(this, FloatingOverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "startAutomation" -> {
                    val steps = call.argument<Any>("steps")
                    val config = call.argument<Any>("config")
                    val conditionImage = call.argument<ByteArray>("conditionImage")
                    val service = BotAccessibilityService.instance
                    if (service == null) {
                        result.error("ACCESSIBILITY_DISABLED", "Accessibility Service is not running", null)
                    } else {
                        service.receiveAutomationSequence(steps, config, conditionImage)
                        result.success(true)
                    }
                }
                "stopAutomation" -> {
                    val service = BotAccessibilityService.instance
                    if (service == null) {
                        result.error("ACCESSIBILITY_DISABLED", "Accessibility Service is not running", null)
                    } else {
                        service.stopAutomationSequence()
                        result.success(true)
                    }
                }
                "requestScreenCapture" -> {
                    val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    val intent = mediaProjectionManager.createScreenCaptureIntent()
                    startActivityForResult(intent, 1001)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val intent = Intent(this, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                }
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        var accessibilityEnabled = 0
        val service = "$packageName/com.example.big_idea.BotAccessibilityService"
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            // Ignored
        }

        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                val stringColonSplitter = TextUtils.SimpleStringSplitter(':')
                stringColonSplitter.setString(settingValue)
                while (stringColonSplitter.hasNext()) {
                    val accessibilityService = stringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
