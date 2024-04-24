package com.example.platform_channel

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "flutter.native/helper";

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)

        methodChannel.setMethodCallHandler { call, result -> 
            // Switch cases
            when (call.method) {
                "greeting" -> {
                    val arguments = call.arguments as Map<String, String>
                    val name = arguments["name"];
                    result.success("Hi $name! I am Kotlin 😎")
                }
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel();

                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error(
                            "UNAVAILABLE",
                            "Could not fetch battery level.",
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }

        }
    }


    private fun getBatteryLevel(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val intent = registerReceiver(null, intentFilter)
            val extraLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100
            val extraScale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            extraLevel / extraScale;
        }
    }
}
