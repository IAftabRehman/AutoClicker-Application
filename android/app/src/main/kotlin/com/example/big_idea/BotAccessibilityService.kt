package com.example.big_idea

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.view.accessibility.AccessibilityEvent
import com.example.big_idea.models.BotActionStep
import com.example.big_idea.models.GlobalConfig
import com.example.big_idea.utils.BotMathUtils
import kotlinx.coroutines.*
import kotlin.coroutines.resume

class BotAccessibilityService : AccessibilityService() {

    var currentSequence: List<BotActionStep> = emptyList()
    var currentConfig: GlobalConfig? = null

    private var executionJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + Job())

    private var isInfiniteMode: Boolean = true
    private var maxRepeatCount: Int = 0
    private var currentRepeatIteration: Int = 0

    private var isSmartModeEnabled: Boolean = true
    private var retryTextToFind: String = "Request Cannot be Processed"
    private var backButtonX: Float = 100f
    private var backButtonY: Float = 150f

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    
    private var windowManager: WindowManager? = null
    private var stopButtonView: View? = null
    
    private var targetTemplateBitmap: Bitmap? = null

    companion object {
        var instance: BotAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("BotService", "Accessibility Service Connected")
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We are doing blind clicks, so we don't heavily rely on UI events yet.
    }

    override fun onInterrupt() {
        Log.d("BotService", "Accessibility Service Interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        executionJob?.cancel()
        serviceScope.cancel()
        instance = null
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        stopService(Intent(this, ScreenCaptureService::class.java))
    }

    fun receiveAutomationSequence(stepsRaw: Any?, configRaw: Any?) {
        try {
            targetTemplateBitmap = null
            
            val configMap = configRaw as? Map<String, Any>
            if (configMap != null) {
                currentConfig = GlobalConfig(
                    idleBreakAfterXSteps = (configMap["idleBreakAfterXSteps"] as? Number)?.toInt() ?: 0,
                    idleBreakDurationMs = (configMap["idleBreakDurationMs"] as? Number)?.toInt() ?: 0,
                    maxSequenceTimeoutMs = (configMap["maxSequenceTimeoutMs"] as? Number)?.toInt() ?: 0
                )
                
                isSmartModeEnabled = true
                retryTextToFind = configMap["targetWaitText"] as? String ?: "Request Cannot be Processed"
                backButtonX = (configMap["smartBackX"] as? Number)?.toFloat() ?: 50f
                backButtonY = (configMap["smartBackY"] as? Number)?.toFloat() ?: 50f
            }

            val stepsList = stepsRaw as? List<Map<String, Any>>
            if (stepsList != null) {
                val parsedSteps = mutableListOf<BotActionStep>()
                for (stepMap in stepsList) {
                    val step = BotActionStep(
                        id = stepMap["id"] as? String ?: "",
                        actionType = stepMap["actionType"] as? String ?: "tap",
                        startX = (stepMap["startX"] as? Number)?.toDouble() ?: 0.0,
                        startY = (stepMap["startY"] as? Number)?.toDouble() ?: 0.0,
                        endX = (stepMap["endX"] as? Number)?.toDouble(),
                        endY = (stepMap["endY"] as? Number)?.toDouble(),
                        minDelayMs = (stepMap["minDelayMs"] as? Number)?.toInt() ?: 0,
                        maxDelayMs = (stepMap["maxDelayMs"] as? Number)?.toInt() ?: 0,
                        minHoldTimeMs = (stepMap["minHoldTimeMs"] as? Number)?.toInt() ?: 0,
                        maxHoldTimeMs = (stepMap["maxHoldTimeMs"] as? Number)?.toInt() ?: 0,
                        jitterRadius = (stepMap["jitterRadius"] as? Number)?.toDouble() ?: 0.0,
                        isCurvedSwipe = stepMap["isCurvedSwipe"] as? Boolean ?: false,
                        waitForText = stepMap["waitForText"] as? String,
                        stepTimeoutMs = (stepMap["stepTimeoutMs"] as? Number)?.toInt() ?: 10000
                    )
                    parsedSteps.add(step)
                }
                currentSequence = parsedSteps
            }

            Log.d("BotService", "Successfully parsed ${currentSequence.size} steps and config. Ready to play.")
        } catch (e: Exception) {
            Log.e("BotService", "Error parsing automation sequence: ${e.message}")
        }
    }

    fun getSequenceSize(): Int = currentSequence.size

    fun updateSequence(newSequence: List<BotActionStep>) {
        currentSequence = newSequence
        Log.d("BotService", "Sequence updated with ${newSequence.size} steps.")
    }

    fun startExecutionLoop() {
        Log.d("BotService", "startExecutionLoop successfully called. Starting loop...")
        if (executionJob?.isActive == true) {
            executionJob?.cancel()
        }
        
        showEmergencyStopButton()
        
        executionJob = serviceScope.launch {
            currentRepeatIteration = 0
            
            while (isActive && (isInfiniteMode || currentRepeatIteration < maxRepeatCount)) {
                Log.d("BotService", "Starting sequence iteration: $currentRepeatIteration")
                FloatingOverlayService.instance?.updateLoopCount(currentRepeatIteration + 1)
                
                if (!analyzeScreenForConditions()) {
                    sendCustomNotification("Action Required", "Bot stopped due to screen change!")
                    stopExecutionLoop("Status: STOPPED (Image Not Found)")
                    stopAutomationSequence()
                    break
                }

                var stepsExecuted = 0
                
                for (step in currentSequence) {
                    if (!isActive) break

                    val stepDelay = BotMathUtils.getRandomTime(step.minDelayMs, step.maxDelayMs)
                    delay(stepDelay)

                    val targetX = BotMathUtils.applyJitter(step.startX.toFloat(), step.jitterRadius)
                    val targetY = BotMathUtils.applyJitter(step.startY.toFloat(), step.jitterRadius)
                    val holdTime = BotMathUtils.getRandomTime(step.minHoldTimeMs, step.maxHoldTimeMs)

                    suspendCancellableCoroutine<Unit> { continuation ->
                        if (step.actionType.equals("tap", ignoreCase = true)) {
                            FloatingOverlayService.instance?.showClickIndicator(targetX, targetY)
                            dispatchTapGesture(targetX, targetY, holdTime) {
                                if (continuation.isActive) continuation.resume(Unit)
                            }
                        } else if (step.actionType.equals("swipe", ignoreCase = true)) {
                            val endX = step.endX?.toFloat() ?: targetX
                            val endY = step.endY?.toFloat() ?: targetY
                            val targetEndX = BotMathUtils.applyJitter(endX, step.jitterRadius)
                            val targetEndY = BotMathUtils.applyJitter(endY, step.jitterRadius)
                            
                            FloatingOverlayService.instance?.showClickIndicator(targetX, targetY)
                            dispatchSwipeGesture(targetX, targetY, targetEndX, targetEndY, holdTime, step.isCurvedSwipe) {
                                if (continuation.isActive) continuation.resume(Unit)
                            }
                        } else {
                            if (continuation.isActive) continuation.resume(Unit)
                        }
                    }
                    
                    stepsExecuted++
                    
                    val breakThreshold = currentConfig?.idleBreakAfterXSteps ?: Int.MAX_VALUE
                    if (breakThreshold > 0 && stepsExecuted >= breakThreshold) {
                        val breakDuration = currentConfig?.idleBreakDurationMs?.toLong() ?: 0L
                        Log.d("BotService", "Taking an idle break for $breakDuration ms after $stepsExecuted steps.")
                        delay(breakDuration)
                        stepsExecuted = 0
                    }
                }
                
                if (!isActive) break
                
                if (isSmartModeEnabled) {
                    Log.d("BotService", "Waiting for network/loading...")
                    FloatingOverlayService.instance?.updateStatus("Status: SCANNING", "#FF9800")
                    val foundRetry = waitForText(retryTextToFind, 15000)
                    
                    if (foundRetry) {
                        Log.d("BotService", "Retry found, clicking back button")
                        dispatchTapGesture(backButtonX, backButtonY, 50) {}
                        delay(1000)
                        FloatingOverlayService.instance?.updateStatus("Status: RUNNING", "#4CAF50")
                    } else {
                        Log.d("BotService", "Success or timeout! Breaking loop.")
                        stopAutomationSequence()
                        sendCustomNotification("Action Required", "Status Changed or Date Found! Bot Stopped.")
                        break
                    }
                }
                
                currentRepeatIteration++
                delay(1000)
            }
            Log.d("BotService", "Execution loop finished")
        }
    }

    private fun dispatchTapGesture(x: Float, y: Float, holdTimeMs: Long, onGestureCompleted: () -> Unit) {
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels

        if (x <= 0 || y <= 0 || x > screenWidth || y > screenHeight) {
            Log.e("BotService", "Invalid coordinates for tap: ($x, $y). Screen size: ${screenWidth}x${screenHeight}")
            onGestureCompleted()
            return
        }

        val path = Path()
        path.moveTo(x, y)
        
        val strokeDescription = GestureDescription.StrokeDescription(path, 0L, holdTimeMs)
        val gesture = GestureDescription.Builder().addStroke(strokeDescription).build()

        val callback = object : AccessibilityService.GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                Log.d("BotService", "Tap Completed")
                onGestureCompleted()
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                Log.d("BotService", "Tap Cancelled")
                onGestureCompleted()
            }
        }

        val dispatched = dispatchGesture(gesture, callback, null)
        if (!dispatched) {
            Log.e("BotService", "Failed to dispatch gesture. Check permissions or coordinates.")
            onGestureCompleted()
        }
    }

    private fun dispatchSwipeGesture(startX: Float, startY: Float, endX: Float, endY: Float, durationMs: Long, isCurved: Boolean = false, onGestureCompleted: () -> Unit) {
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels

        if (startX <= 0 || startY <= 0 || startX > screenWidth || startY > screenHeight ||
            endX <= 0 || endY <= 0 || endX > screenWidth || endY > screenHeight) {
            Log.e("BotService", "Invalid coordinates for swipe: ($startX, $startY) to ($endX, $endY)")
            onGestureCompleted()
            return
        }

        val path = Path()
        path.moveTo(startX, startY)
        
        if (isCurved) {
            val midX = (startX + endX) / 2
            val midY = (startY + endY) / 2
            
            // Generate a random offset between 50f and 200f
            val randomOffset = kotlin.random.Random.nextFloat() * 150f + 50f
            
            // Apply offset to create control points for the quadratic Bezier curve
            val controlX = midX + randomOffset
            val controlY = midY - randomOffset
            
            path.quadTo(controlX, controlY, endX, endY)
        } else {
            path.lineTo(endX, endY)
        }
        
        val strokeDescription = GestureDescription.StrokeDescription(path, 0L, durationMs)
        val gesture = GestureDescription.Builder().addStroke(strokeDescription).build()

        val callback = object : AccessibilityService.GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                Log.d("BotService", "Swipe Completed")
                onGestureCompleted()
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                Log.d("BotService", "Swipe Cancelled")
                onGestureCompleted()
            }
        }

        val dispatched = dispatchGesture(gesture, callback, null)
        if (!dispatched) {
            Log.e("BotService", "Failed to dispatch gesture. Check permissions or coordinates.")
            onGestureCompleted()
        }
    }

    fun stopExecutionLoop(reason: String = "Status: STOPPED") {
        executionJob?.cancel()
        hideEmergencyStopButton()
        FloatingOverlayService.instance?.updateStatus(reason, "#F44336")
        Log.d("BotService", "Execution loop paused/stopped: $reason")
    }

    fun stopAutomationSequence() {
        executionJob?.cancel()
        currentSequence = emptyList()
        currentConfig = null
        hideEmergencyStopButton()
        stopService(Intent(this, ScreenCaptureService::class.java))
        Log.d("BotService", "Automation Sequence Stopped and Cleared.")
    }

    private fun isTextPresentOnScreen(targetText: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val nodes = rootNode.findAccessibilityNodeInfosByText(targetText)
        val found = nodes.isNotEmpty()
        nodes.forEach { it.recycle() }
        rootNode.recycle()
        return found
    }

    private suspend fun waitForText(targetText: String, timeoutMs: Long = 15000): Boolean = withContext(Dispatchers.Default) {
        val startTime = System.currentTimeMillis()
        while (System.currentTimeMillis() - startTime < timeoutMs) {
            if (!isActive) return@withContext false
            if (isTextPresentOnScreen(targetText)) {
                return@withContext true
            }
            delay(500)
        }
        return@withContext false
    }

    fun setupScreenCapture(resultCode: Int, data: Intent) {
        val metrics = resources.displayMetrics
        val density = metrics.densityDpi
        val width = metrics.widthPixels
        val height = metrics.heightPixels

        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )
    }

    private suspend fun analyzeScreenForConditions(): Boolean = withContext(Dispatchers.Default) {
        val template = targetTemplateBitmap
        if (template == null) {
            // If no image is provided, continue loop as normal
            return@withContext true
        }

        val image = imageReader?.acquireLatestImage() ?: return@withContext true
        
        try {
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * image.width
            
            val bitmap = Bitmap.createBitmap(image.width + rowPadding / pixelStride, image.height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(buffer)
            
            // Crop the bitmap to remove the padding
            val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
            
            // Fast pattern matching via downscaling
            val scaleFactor = 0.25f
            val scaledWidth = (croppedBitmap.width * scaleFactor).toInt()
            val scaledHeight = (croppedBitmap.height * scaleFactor).toInt()
            val scaledScreen = Bitmap.createScaledBitmap(croppedBitmap, scaledWidth, scaledHeight, false)
            
            val scaledTemplateWidth = (template.width * scaleFactor).toInt()
            val scaledTemplateHeight = (template.height * scaleFactor).toInt()
            
            if (scaledTemplateWidth <= 0 || scaledTemplateHeight <= 0 || scaledTemplateWidth > scaledWidth || scaledTemplateHeight > scaledHeight) {
                bitmap.recycle()
                if (scaledScreen != bitmap) scaledScreen.recycle()
                return@withContext true 
            }
            
            val scaledTemplate = Bitmap.createScaledBitmap(template, scaledTemplateWidth, scaledTemplateHeight, false)
            
            val screenPixels = IntArray(scaledWidth * scaledHeight)
            scaledScreen.getPixels(screenPixels, 0, scaledWidth, 0, 0, scaledWidth, scaledHeight)
            
            val templatePixels = IntArray(scaledTemplateWidth * scaledTemplateHeight)
            scaledTemplate.getPixels(templatePixels, 0, scaledTemplateWidth, 0, 0, scaledTemplateWidth, scaledTemplateHeight)
            
            var found = false
            
            val xMax = scaledWidth - scaledTemplateWidth
            val yMax = scaledHeight - scaledTemplateHeight
            
            val step = 2 
            val tolerance = 30

            for (y in 0..yMax step step) {
                for (x in 0..xMax step step) {
                    var match = true
                    val testPoints = listOf(
                        Pair(0, 0),
                        Pair(scaledTemplateWidth / 2, scaledTemplateHeight / 2),
                        Pair(scaledTemplateWidth - 1, scaledTemplateHeight - 1)
                    )
                    
                    for (point in testPoints) {
                        val tx = point.first
                        val ty = point.second
                        val sp = screenPixels[(y + ty) * scaledWidth + (x + tx)]
                        val tp = templatePixels[ty * scaledTemplateWidth + tx]
                        
                        if (!colorMatch(sp, tp, tolerance)) {
                            match = false
                            break
                        }
                    }
                    
                    if (match) {
                        var detailMatch = true
                        for (ty in 0 until scaledTemplateHeight step 2) {
                            for (tx in 0 until scaledTemplateWidth step 2) {
                                val sp = screenPixels[(y + ty) * scaledWidth + (x + tx)]
                                val tp = templatePixels[ty * scaledTemplateWidth + tx]
                                if (!colorMatch(sp, tp, tolerance)) {
                                    detailMatch = false
                                    break
                                }
                            }
                            if (!detailMatch) break
                        }
                        if (detailMatch) {
                            found = true
                            break
                        }
                    }
                }
                if (found) break
            }
            
            bitmap.recycle()
            croppedBitmap.recycle()
            if (scaledScreen != croppedBitmap) scaledScreen.recycle()
            if (scaledTemplate != template) scaledTemplate.recycle()
            
            if (!found) {
                Log.d("BotService", "Target image NOT found on screen. Stopping.")
                return@withContext false
            }
            
            return@withContext true
        } catch (e: Exception) {
            Log.e("BotService", "Error analyzing screen: ${e.message}")
            return@withContext true
        } finally {
            image.close()
        }
    }
    
    private fun colorMatch(c1: Int, c2: Int, tolerance: Int): Boolean {
        val r1 = Color.red(c1)
        val g1 = Color.green(c1)
        val b1 = Color.blue(c1)
        
        val r2 = Color.red(c2)
        val g2 = Color.green(c2)
        val b2 = Color.blue(c2)
        
        return Math.abs(r1 - r2) <= tolerance && Math.abs(g1 - g2) <= tolerance && Math.abs(b1 - b2) <= tolerance
    }

    private fun sendCustomNotification(title: String, text: String) {
        val channelId = "bot_alert_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Bot Alerts", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notification = android.app.Notification.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .build()
            manager.notify(1001, notification)
        } else {
            val notification = android.app.Notification.Builder(this)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .build()
            manager.notify(1001, notification)
        }
    }

    private fun showEmergencyStopButton() {
        if (stopButtonView != null) return

        Handler(Looper.getMainLooper()).post {
            if (windowManager == null) {
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            }

            val stopButton = Button(this).apply {
                text = "⏹ STOP"
                setBackgroundColor(Color.parseColor("#D32F2F")) // Red color
                setTextColor(Color.WHITE)
                setPadding(16, 16, 16, 16)
                setOnClickListener {
                    stopAutomationSequence()
                }
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 20
                y = 100 // Avoid overlapping status bar
            }

            windowManager?.addView(stopButton, params)
            stopButtonView = stopButton
        }
    }

    private fun hideEmergencyStopButton() {
        Handler(Looper.getMainLooper()).post {
            stopButtonView?.let {
                try {
                    windowManager?.removeView(it)
                } catch (e: Exception) {
                    // Ignored
                }
                stopButtonView = null
            }
        }
    }
}
