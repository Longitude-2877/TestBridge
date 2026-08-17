package com.example.elderlauncher

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.ContactsContract
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.graphics.PixelFormat
import android.media.AudioManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.widget.TextView
import android.view.WindowManager.LayoutParams
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val audioManager by lazy { getSystemService(Context.AUDIO_SERVICE) as AudioManager }
    private val cameraManager by lazy { getSystemService(Context.CAMERA_SERVICE) as CameraManager }
    private var torchCameraId: String? = null
    private val volumeChannel by lazy {
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "elders/volume")
    }

    private val wm by lazy { getSystemService(Context.WINDOW_SERVICE) as WindowManager }
    private var overlayTop: View? = null
    private var overlayBottom: View? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        hideSystemBars()
        window.decorView.setOnSystemUiVisibilityChangeListener {
            hideSystemBars()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemBars()
            // We are back in our launcher - remove the overlay over external apps.
            showOverlay(false)
        }
    }

    private var hidingBars = false

    @SuppressLint("ObsoleteSdkInt")
    private fun hideSystemBars() {
        if (hidingBars) return
        hidingBars = true
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.insetsController?.apply {
                    hide(WindowInsets.Type.systemBars())
                    systemBarsBehavior =
                        WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                    )
            }
        } finally {
            hidingBars = false
        }
    }

    // Requirement 12: intercept the hardware volume keys so the system volume
    // UI never appears; we show our own slider instead (handled on the Flutter side).
    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        if (event?.action == KeyEvent.ACTION_DOWN &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)
        ) {
            val dir = if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) 1 else -1
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                if (dir > 0) AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER,
                0
            )
            volumeChannel.invokeMethod("key", dir)
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun getVolume(): Double {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val cur = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return if (max == 0) 0.5 else cur.toDouble() / max
    }

    private fun setVolume(v: Double) {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val target = (v * max).toInt().coerceIn(0, max)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
    }

    private fun setFlashlight(on: Boolean): Boolean {
        return try {
            if (torchCameraId == null) {
                torchCameraId = cameraManager.cameraIdList.firstOrNull { id ->
                    cameraManager.getCameraCharacteristics(id)
                        .get(CameraCharacteristics.LENS_FACING) ==
                        CameraCharacteristics.LENS_FACING_BACK
                }
            }
            torchCameraId?.let { cameraManager.setTorchMode(it, on) }
            true
        } catch (e: Exception) {
            false
        }
    }

    // Requirement 13: draw our top & bottom bars over external apps so they
    // stay visible without blocking the app (the overlay is not touchable).
    @SuppressLint("InflateParams")
    private fun showOverlay(show: Boolean) {
        try {
            if (show) {
                if (overlayTop != null || !Settings.canDrawOverlays(this)) return
                if (!Settings.canDrawOverlays(this)) {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                    return
                }
                val top = TextView(this).apply {
                    text = "Elder Launcher"
                    textSize = 18f
                    setBackgroundColor(0xFFFFFFFF.toInt())
                    setTextColor(0xFF000000.toInt())
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(40, 0, 0, 0)
                }
                val topParams = LayoutParams(
                    LayoutParams.MATCH_PARENT,
                    120,
                    LayoutParams.TYPE_APPLICATION_OVERLAY,
                    LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCHABLE,
                    PixelFormat.TRANSLUCENT
                )
                topParams.gravity = Gravity.TOP
                wm.addView(top, topParams)
                overlayTop = top

                val bottom = TextView(this).apply {
                    text = "Home   ·   Back"
                    textSize = 18f
                    setBackgroundColor(0xFFFFFFFF.toInt())
                    setTextColor(0xFF000000.toInt())
                    gravity = Gravity.CENTER
                }
                val bottomParams = LayoutParams(
                    LayoutParams.MATCH_PARENT,
                    120,
                    LayoutParams.TYPE_APPLICATION_OVERLAY,
                    LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCHABLE,
                    PixelFormat.TRANSLUCENT
                )
                bottomParams.gravity = Gravity.BOTTOM
                wm.addView(bottom, bottomParams)
                overlayBottom = bottom
            } else {
                overlayTop?.let { wm.removeView(it) }
                overlayTop = null
                overlayBottom?.let { wm.removeView(it) }
                overlayBottom = null
            }
        } catch (_: Exception) {
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "elders/phone")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "placeCall" -> {
                        val number = call.arguments as? String
                        if (number.isNullOrEmpty()) {
                            result.error("BAD_NUMBER", "Empty number", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("CALL_FAILED", e.message ?: "Call failed", null)
                        }
                    }
                    "getContacts" -> result.success(queryContacts())
                    "addContact" -> {
                        val args = call.arguments as? Map<*, *>
                        val name = args?.get("name") as? String ?: ""
                        val number = args?.get("number") as? String ?: ""
                        try {
                            val ok = addContact(name, number)
                            if (ok) result.success(null)
                            else result.error("SAVE_FAILED", "Could not save contact", null)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message ?: "Save failed", null)
                        }
                    }
                    "openSettings" -> {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SETTINGS_FAILED", e.message ?: "Could not open settings", null)
                        }
                    }
                    "requestDefaultLauncher" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val roleManager = getSystemService(
                                    android.app.role.RoleManager::class.java
                                )
                                startActivity(
                                    roleManager.createRequestRoleIntent(
                                        android.app.role.RoleManager.ROLE_HOME
                                    )
                                )
                            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                startActivity(Intent(android.provider.Settings.ACTION_HOME_SETTINGS))
                            } else {
                                startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ROLE_FAILED", e.message ?: "Could not open default app settings", null)
                        }
                    }
                    "getInstalledApps" -> result.success(getInstalledApps())
                    "getAppIcon" -> {
                        val pkg = call.arguments as? String ?: ""
                        result.success(getAppIconBytes(pkg))
                    }
                    "launchApp" -> {
                        val pkg = call.arguments as? String
                        if (pkg.isNullOrEmpty()) {
                            result.error("BAD_PACKAGE", "Empty package", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val launch = packageManager.getLaunchIntentForPackage(pkg)
                            if (launch == null) {
                                result.error("NOT_FOUND", "App not found", null)
                            } else {
                                // Requirement 13: show our bars over the external app.
                                showOverlay(true)
                                startActivity(launch)
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", e.message ?: "Could not open app", null)
                        }
                    }
                    "setFlashlight" -> {
                        val on = call.arguments as? Boolean ?: false
                        result.success(setFlashlight(on))
                    }
                    "getVolume" -> result.success(getVolume())
                    "setVolume" -> {
                        val v = call.arguments as? Double ?: 0.5
                        setVolume(v)
                        result.success(null)
                    }
                    "showOverlay" -> {
                        val show = call.arguments as? Boolean ?: false
                        showOverlay(show)
                        result.success(null)
                    }
                    "exitLauncher" -> {
                        finishAffinity()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun addContact(name: String, number: String): Boolean {
        if (name.isBlank() || number.isBlank()) return false
        val ops = ArrayList<android.content.ContentProviderOperation>()
        ops.add(
            android.content.ContentProviderOperation
                .newInsert(ContactsContract.RawContacts.CONTENT_URI)
                .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                .build()
        )
        ops.add(
            android.content.ContentProviderOperation
                .newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(
                    ContactsContract.Data.MIMETYPE,
                    ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE
                )
                .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                .build()
        )
        ops.add(
            android.content.ContentProviderOperation
                .newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(
                    ContactsContract.Data.MIMETYPE,
                    ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE
                )
                .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, number)
                .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                .build()
        )
        try {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun queryContacts(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone._ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )
        try {
            contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                null,
                null,
                "upper(${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME}) ASC"
            )?.use { cursor ->
                val nameIdx = cursor.getColumnIndexOrThrow(
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                )
                val numIdx = cursor.getColumnIndexOrThrow(
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                )
                while (cursor.moveToNext()) {
                    val name = cursor.getString(nameIdx) ?: ""
                    val number = cursor.getString(numIdx) ?: ""
                    if (number.isNotBlank()) {
                        list.add(mapOf("name" to name, "number" to number))
                    }
                }
            }
        } catch (_: Exception) {
        }
        return list
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val map = linkedMapOf<String, Map<String, String>>()
        try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            val resolveInfo = packageManager.queryIntentActivities(intent, 0)
            for (ri in resolveInfo) {
                val packageName = ri.activityInfo.packageName
                if (packageName == this.packageName) continue
                val name = ri.loadLabel(packageManager)?.toString() ?: packageName
                map[packageName] = mapOf("name" to name, "package" to packageName)
            }
        } catch (_: Exception) {
        }
        return map.values.sortedBy { it["name"] }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap: android.graphics.Bitmap = when (drawable) {
                is android.graphics.drawable.BitmapDrawable -> drawable.bitmap
                else -> {
                    val b = android.graphics.Bitmap.createBitmap(
                        128, 128, android.graphics.Bitmap.Config.ARGB_8888
                    )
                    val canvas = android.graphics.Canvas(b)
                    drawable.setBounds(0, 0, 128, 128)
                    drawable.draw(canvas)
                    b
                }
            }
            val out = java.io.ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        } catch (_: Exception) {
            null
        }
    }
}
