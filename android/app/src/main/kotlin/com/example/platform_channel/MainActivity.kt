package com.example.platform_channel

import NativeMethodsApi
import FlutterEventsApi
import GreetingRequest
import GreetingResponse
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity(), NativeMethodsApi {
    private var flutterEventsApi: FlutterEventsApi? = null
    private val handler = Handler(Looper.getMainLooper())
    private var timeUpdateRunnable: Runnable? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup the Pigeon-generated API
        NativeMethodsApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
        
        // Get the Flutter API instance
        flutterEventsApi = FlutterEventsApi(flutterEngine.dartExecutor.binaryMessenger)
        
        // Start sending time updates
        startTimeUpdates()
    }

    // Implement NativeMethodsApi methods with callback pattern
    override fun greeting(request: GreetingRequest, callback: (Result<GreetingResponse>) -> Unit) {
        var response = GreetingResponse("Hi ${request.name}! I am Kotlin 😎")
        callback(Result.success(response))
    }

    override fun getBatteryLevel(callback: (Result<Long>) -> Unit) {
        val batteryLevel = getBatteryLevelInternal()
        callback(Result.success(batteryLevel.toLong()))
    }

    // Utility function to get battery level
    private fun getBatteryLevelInternal(): Int {
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
    
    // Handle the time updates (equivalent to the EventChannel)
    private fun startTimeUpdates() {
        timeUpdateRunnable = object : Runnable {
            override fun run() {
                val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                flutterEventsApi?.onTimeUpdate(time) { /* Optional error callback */ }
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(timeUpdateRunnable!!)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        timeUpdateRunnable?.let { handler.removeCallbacks(it) }
    }
}