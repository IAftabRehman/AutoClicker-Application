package com.example.big_idea

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class FloatingOverlayService : Service() {
    private val TAG = "OverlayService"

    companion object {
        var instance: FloatingOverlayService? = null
    }

    private lateinit var windowManager: WindowManager
    private lateinit var windowParams: WindowManager.LayoutParams
    private var controlPanelView: View? = null
    private var statusView: TextView? = null
    private var loopCountView: TextView? = null
    private lateinit var layoutParams: WindowManager.LayoutParams
    
    private val targetViews = mutableListOf<View>()

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Service Created")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "bot_overlay_channel"
            val channelName = "Bot Overlay Service"
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)

            val notification = Notification.Builder(this, channelId)
                .setContentTitle("Bot Overlay Active")
                .setContentText("Floating controls are running...")
                .setSmallIcon(android.R.drawable.ic_menu_compass)
                .build()

            startForeground(1, notification)
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }

        buildControlPanel()
    }

    private fun buildControlPanel() {
        val linearLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#CC000000")) // Dark semi-transparent
            setPadding(20, 20, 20, 20)
        }

        val headerView = TextView(this).apply {
            text = "Bot Menu"
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#555555"))
            setPadding(10, 10, 10, 10)
        }

        val statusTv = TextView(this).apply {
            text = "Status: IDLE"
            setTextColor(Color.parseColor("#FF9800")) // Orange
            gravity = Gravity.CENTER
            setPadding(5, 5, 5, 10)
            textSize = 12f
        }
        statusView = statusTv

        val loopTv = TextView(this).apply {
            text = "Loops: 0"
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(5, 0, 5, 10)
            textSize = 12f
        }
        loopCountView = loopTv

        val btnAddTarget = Button(this).apply { text = "+ Add Target" }
        val btnSave = Button(this).apply { text = "Save & Exit" }
        val btnClose = Button(this).apply { text = "Close Menu" }

        val playbackBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 10, 0, 10)
        }

        val layoutParamsWeight = LinearLayout.LayoutParams(
            0,
            LinearLayout.LayoutParams.WRAP_CONTENT,
            1f
        ).apply {
            setMargins(5, 0, 5, 0)
        }

        val btnPlay = Button(this).apply {
            text = "▶ Play"
            setBackgroundColor(Color.parseColor("#4CAF50"))
            setTextColor(Color.WHITE)
            layoutParams = layoutParamsWeight
        }

        val btnPause = Button(this).apply {
            text = "⏸ Pause"
            setBackgroundColor(Color.parseColor("#FF9800"))
            setTextColor(Color.WHITE)
            layoutParams = layoutParamsWeight
        }

        val btnStop = Button(this).apply {
            text = "⏹ Stop"
            setBackgroundColor(Color.parseColor("#F44336"))
            setTextColor(Color.WHITE)
            layoutParams = layoutParamsWeight
        }

        playbackBar.addView(btnPlay)
        playbackBar.addView(btnPause)
        playbackBar.addView(btnStop)

        linearLayout.addView(headerView)
        linearLayout.addView(statusTv)
        linearLayout.addView(loopTv)
        linearLayout.addView(btnAddTarget)
        linearLayout.addView(playbackBar)
        linearLayout.addView(btnSave)
        linearLayout.addView(btnClose)

        controlPanelView = linearLayout
        windowManager.addView(controlPanelView, layoutParams)

        setupDragging(headerView)

        btnAddTarget.setOnClickListener {
            addTargetCrosshair()
        }

        btnPlay.setOnClickListener {
            val service = BotAccessibilityService.instance
            if (service == null) {
                Toast.makeText(this@FloatingOverlayService, "Please enable Accessibility Service first.", Toast.LENGTH_SHORT).show()
            } else if (service.currentSequence.isNotEmpty()) {
                service.startExecutionLoop()
                updateStatus("Status: RUNNING", "#4CAF50")
            }
            Log.d("OverlayUI", "Play Button Clicked")
        }

        btnPause.setOnClickListener {
            Log.d("OverlayUI", "Pause Button Clicked")
        }

        btnStop.setOnClickListener {
            val service = BotAccessibilityService.instance
            service?.stopExecutionLoop("Status: STOPPED (Manual)")
            Log.d("OverlayUI", "Stop Button Clicked")
        }

        btnSave.setOnClickListener {
            val coordinatesList = ArrayList<HashMap<String, Int>>()
            for (target in targetViews) {
                val params = target.layoutParams as WindowManager.LayoutParams
                // Ensure exact calculation: Top-Left + Half Width/Height
                val exactX = params.x + (150 / 2)
                val exactY = params.y + (150 / 2)
                val map = HashMap<String, Int>()
                map["x"] = exactX
                map["y"] = exactY
                coordinatesList.add(map)
            }
            val intent = Intent("com.autobot.app.TARGETS_SAVED")
            intent.putExtra("coordinates", coordinatesList)
            sendBroadcast(intent)

            cleanupTargets()
            stopSelf()
        }

        btnClose.setOnClickListener {
            val service = BotAccessibilityService.instance
            service?.stopAutomationSequence()
            cleanupTargets()
            stopSelf()
        }
    }

    private fun addTargetCrosshair() {
        val targetSize = 150
        val targetLayout = FrameLayout(this).apply {
            val bgDrawable = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#22FF0000")) // Very transparent red
                setStroke(2, Color.RED)
            }
            background = bgDrawable
        }

        // Add a sharp red dot in the center
        val centerDot = View(this).apply {
            setBackgroundColor(Color.RED)
            layoutParams = FrameLayout.LayoutParams(6, 6, Gravity.CENTER)
        }
        targetLayout.addView(centerDot)

        // Add thin vertical line
        val vLine = View(this).apply {
            setBackgroundColor(Color.parseColor("#88FF0000"))
            layoutParams = FrameLayout.LayoutParams(2, FrameLayout.LayoutParams.MATCH_PARENT, Gravity.CENTER)
        }
        targetLayout.addView(vLine)

        // Add thin horizontal line
        val hLine = View(this).apply {
            setBackgroundColor(Color.parseColor("#88FF0000"))
            layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, 2, Gravity.CENTER)
        }
        targetLayout.addView(hLine)

        val targetText = TextView(this).apply {
            text = (targetViews.size + 1).toString()
            setTextColor(Color.WHITE)
            textSize = 16f
            gravity = Gravity.TOP or Gravity.START
            setPadding(15, 15, 0, 0)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        targetLayout.addView(targetText)

        val targetParams = WindowManager.LayoutParams(
            targetSize, targetSize,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 500
            y = 500
        }

        setupTargetDragging(targetLayout, targetParams, targetSize)

        windowManager.addView(targetLayout, targetParams)
        targetViews.add(targetLayout)
    }

    private fun setupTargetDragging(targetView: View, params: WindowManager.LayoutParams, targetSize: Int) {
        targetView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_MOVE -> {
                    // Apply touch offset so finger doesn't block the crosshair's center dot
                    params.x = (event.rawX - targetSize / 2).toInt()
                    params.y = (event.rawY - targetSize / 2 - 120).toInt()
                    windowManager.updateViewLayout(targetView, params)
                    true
                }
                else -> true
            }
        }
    }

    private fun setupDragging(handleView: View) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        handleView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams.x
                    initialY = layoutParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    layoutParams.x = initialX + (event.rawX - initialTouchX).toInt()
                    layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                    controlPanelView?.let {
                        windowManager.updateViewLayout(it, layoutParams)
                    }
                    true
                }
                else -> false
            }
        }
    }

    fun updateStatus(text: String, colorHex: String) {
        Handler(Looper.getMainLooper()).post {
            statusView?.text = text
            statusView?.setTextColor(Color.parseColor(colorHex))
        }
    }

    fun updateLoopCount(count: Int) {
        Handler(Looper.getMainLooper()).post {
            loopCountView?.text = "Loops: $count"
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service Started")
        return START_STICKY
    }

    private fun cleanupTargets() {
        for (target in targetViews) {
            windowManager.removeView(target)
        }
        targetViews.clear()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Service Destroyed")
        stopForeground(true)
        cleanupTargets()
        controlPanelView?.let {
            windowManager.removeView(it)
        }
    }

    fun showClickIndicator(x: Float, y: Float) {
        val indicatorView = View(this).apply {
            val bgDrawable = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#880000FF")) // Semi-transparent blue
            }
            background = bgDrawable
        }

        val size = 50
        val indicatorParams = WindowManager.LayoutParams(
            size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = (x - size / 2).toInt()
            this.y = (y - size / 2).toInt()
        }

        windowManager.addView(indicatorView, indicatorParams)

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                windowManager.removeView(indicatorView)
            } catch (e: Exception) {
                // View might already be removed
            }
        }, 300)
    }
}
