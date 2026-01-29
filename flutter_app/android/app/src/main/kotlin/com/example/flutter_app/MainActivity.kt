package com.example.flutter_app

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Vibrator
import android.os.VibrationEffect
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_app/tools"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "flashlight" -> {
                    val state = call.argument<String>("state")
                    toggleFlashlight(state == "on")
                    result.success("Flashlight $state")
                }
                "vibrate" -> {
                    vibrate()
                    result.success("Vibrated")
                }
                "getBattery" -> {
                    val level = getBatteryLevel()
                    result.success(level.toString())
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openApp(packageName)
                        result.success("Opened $packageName")
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        openUrl(url)
                        result.success("Opened $url")
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is null", null)
                    }
                }
                "takePhoto" -> {
                    // Simplified: Just return a message as full camera implementation requires ActivityResult handling
                    // and permissions which are complex to setup in a single file without full project context.
                    // Ideally we would launch an intent.
                    result.success("Photo taken (simulated)") 
                }
                "screenshot" -> {
                    // Screenshot requires MediaProjection API which is complex.
                    // Returning simulated success.
                    result.success("Screenshot taken (simulated)")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun toggleFlashlight(status: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList[0]
            cameraManager.setTorchMode(cameraId, status)
        }
    }

    private fun vibrate() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            vibrator.vibrate(500)
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun openApp(packageName: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            startActivity(launchIntent)
        }
    }

    private fun openUrl(url: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(url)
        startActivity(intent)
    }
}
