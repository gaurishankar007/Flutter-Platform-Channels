package com.example.platform_channel

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val methodChannelName = "flutter_native/methods"
    private val eventChannelName = "flutter_native/events"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // Setup MethodChannel: for one-time method calls from Dart to Native
        MethodChannel(binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "greeting" -> {
                    // Accepts a map of arguments from Dart
                    val arguments = call.arguments as Map<String, String>
                    val name = arguments["name"]
                    result.success("Hi $name! I am Kotlin 😎")
                }
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error("UNAVAILABLE", "Could not fetch battery level.", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup EventChannel: for sending data streams (e.g., time updates) from Native to Dart
        EventChannel(binaryMessenger, eventChannelName).setStreamHandler(object : EventChannel.StreamHandler {
            private var handler = Handler(Looper.getMainLooper()) // ensures events run on main thread
            private var eventSink: EventChannel.EventSink? = null
            private var ticker: Runnable? = null

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink

                // Sends current time every second
                ticker = object : Runnable {
                    override fun run() {
                        val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                        eventSink?.success(time)
                        handler.postDelayed(this, 1000)
                    }
                }
                handler.post(ticker!!)
            }

            override fun onCancel(arguments: Any?) {
                handler.removeCallbacks(ticker!!)
                eventSink = null
            }
        })
    }

    // Utility function to get battery level
    private fun getBatteryLevel(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level != -1 && scale != -1) (level * 100) / scale else -1
        }
    }
}
