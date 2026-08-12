package com.example.elderlauncher

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.BatteryManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Shows the ElderLauncher top bar (time + battery) and bottom bar
 * (SOS / Home / Back) on top of external apps while they run.
 * The launcher stops this service when it comes back to the foreground.
 */
class BarsOverlayService : Service() {

    companion object {
        const val ACTION_STOP = "com.example.elderlauncher.STOP_OVERLAY"
    }

    private lateinit var wm: WindowManager
    private var topBar: LinearLayout? = null
    private var bottomBar: LinearLayout? = null
    private var clock: Runnable? = null
    private val handler = Handler(Looper.getMainLooper())
    private val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (topBar == null || bottomBar == null) {
            addBars()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        clock?.let { handler.removeCallbacks(it) }
        topBar?.let { try { wm.removeView(it) } catch (_: Exception) {} }
        bottomBar?.let { try { wm.removeView(it) } catch (_: Exception) {} }
        topBar = null
        bottomBar = null
    }

    private fun addBars() {
        wm = getSystemService(WINDOW_SERVICE) as WindowManager

        val timeText = TextView(this).apply {
            textSize = 26f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setTextColor(0xFF2B2B39.toInt())
        }
        val batteryText = TextView(this).apply {
            textSize = 18f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setTextColor(0xFF2B2B39.toInt())
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
        }

        topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(20), dp(8), dp(20), dp(8))
            background = solid(0xFFFFFFFF.toInt())
            elevation = dp(6).toFloat()
            addView(timeText, LinearLayout.LayoutParams(0, dp(44), 1f))
            addView(batteryText, LinearLayout.LayoutParams(dp(80), dp(44)))
        }

        val sos = navButton("SOS", 0xFFFF5B5B.toInt()) {
            Toast.makeText(this, "Coming soon!", Toast.LENGTH_SHORT).show()
        }
        val home = navButton("HOME", 0xFF2B2B39.toInt()) { openLauncher() }
        val back = navButton("BACK", 0xFF2B2B39.toInt()) { openLauncher() }

        bottomBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(10), dp(8), dp(10))
            background = solid(0xFFFFFFFF.toInt())
            elevation = dp(6).toFloat()
            addView(sos, LinearLayout.LayoutParams(0, dp(58), 1f))
            addView(home, LinearLayout.LayoutParams(0, dp(58), 1f))
            addView(back, LinearLayout.LayoutParams(0, dp(58), 1f))
        }

        val overlayFlags =
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN

        val topParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            overlayFlags,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP }

        val bottomParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            overlayFlags,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.BOTTOM }

        try {
            wm.addView(topBar, topParams)
            wm.addView(bottomBar, bottomParams)
        } catch (_: Exception) {
            Toast.makeText(this, "Overlay not allowed", Toast.LENGTH_SHORT).show()
            stopSelf()
            return
        }

        val runnable = object : Runnable {
            override fun run() {
                timeText.text = timeFormat.format(Date())
                batteryText.text = "${batteryLevel()}%"
                handler.postDelayed(this, 1000)
            }
        }
        clock = runnable
        handler.post(runnable)
    }

    private fun navButton(label: String, color: Int, onClick: () -> Unit): TextView {
        val tv = TextView(this)
        tv.text = label
        tv.gravity = Gravity.CENTER
        tv.textSize = 18f
        tv.typeface = android.graphics.Typeface.DEFAULT_BOLD
        tv.setTextColor(color)
        tv.background = rounded(0xFFF6F7FB.toInt(), dp(14))
        tv.setOnClickListener { onClick() }
        return tv
    }

    private fun batteryLevel(): Int {
        return try {
            val bm = getSystemService(BATTERY_SERVICE) as BatteryManager
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (_: Exception) {
            100
        }
    }

    private fun openLauncher() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        startActivity(intent)
    }

    private fun solid(color: Int) = GradientDrawable().apply {
        setColor(color)
        setCornerRadius(0f)
    }

    private fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
        setColor(color)
        setCornerRadius(radius.toFloat())
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
}
