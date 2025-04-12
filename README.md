# 🕊️ Flutter Platform Channels with Pigeon

This guide covers how to use **[Pigeon](https://pub.dev/packages/pigeon)** to create type-safe, structured communication between Flutter and native code (Android & iOS) — without manually wiring up `MethodChannel`, `EventChannel`, or `BasicMessageChannel`.

---

## 🚀 Why Use Pigeon?

| Feature                    | Benefit                                                   |
| -------------------------- | --------------------------------------------------------- |
| ✅ Type Safety             | Compile-time checks, no dynamic `Map` or `String` parsing |
| ✅ No Manual Channel Setup | Auto-generated boilerplate for native integration         |
| ✅ Structured Data         | Use Dart/Swift/Kotlin classes, not loose arguments        |
| ✅ Event Handling          | Replace `EventChannel` with callback-based APIs           |
| ✅ Centralized Config      | Use `@ConfigurePigeon()` for easy setup across platforms  |

---

## 🧰 Setup & Configuration

### 📦 Add `pigeon` to `dev_dependencies`

```yaml
dev_dependencies:
  pigeon: ^25.3.0
```

### 🛠️ Define APIs using pigeon.dart

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/generated/pigeon_api.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/platform_channel/PigeonApi.kt',
    kotlinOptions: KotlinOptions(),
    swiftOut: 'ios/Runner/PigeonApi.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: "com.example.platform_channel", // Package name needed
  ),
)
// Define message classes for data exchange
class GreetingRequest {
  String? name;
}

class GreetingResponse {
  String? message;
}

// Define method channel API
@HostApi()
abstract class NativeMethodsApi {
  @async
  GreetingResponse greeting(GreetingRequest request);

  @async
  int getBatteryLevel();
}

// Define event channel API using a callback interface
@FlutterApi()
abstract class FlutterEventsApi {
  void onTimeUpdate(String time);
}
```

### 🛠️ Generate code

Run this command:

```sh
dart run pigeon --input lib/pigeons/pigeon_configuration.dart
```

### 🤖 Android Setup (In MainActivity.kt)

```kotlin
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
```

### 🍎 iOS Setup (In AppDelegate.swift)

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, NativeMethodsApi {
    private var timer: Timer?
    private var flutterApi: FlutterEventsApi?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let binaryMessenger = controller.binaryMessenger

        // Register Flutter -> Native API
        NativeMethodsApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
        // Setup FlutterEventsApi for native -> Flutter communication
        flutterApi = FlutterEventsApi(binaryMessenger: binaryMessenger)
        // Start timer to send time updates
        startSendingTime()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func greeting(
        request: GreetingRequest, completion: @escaping (Result<GreetingResponse, Error>) -> Void
    ) {
        var response = GreetingResponse()
        if let name = request.name {
            response.message = "Hi \(name)! I am Swift 🍎"
        } else {
            response.message = "Hello from Swift"
        }
        completion(.success(response))
    }

    func getBatteryLevel(completion: @escaping (Result<Int64, Error>) -> Void) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            completion(.success(Int64(level * 100)))
        } else {
            completion(.success(Int64(-1)))
        }
    }

    func startSendingTime() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: Date())
            self.flutterApi?.onTimeUpdate(time: timeString, completion: { _ in })
        }
    }
}
```

### 🧑‍💻 Dart Usage (Flutter Side)

#### Make a controller to call the native method/event

```dart
import 'dart:async' show StreamController;
import 'dart:developer' show log;

import '../pigeons/generated/pigeon_api.dart';

class PlatformController {
  // API client generated by Pigeon
  final _methodsApi = NativeMethodsApi();
  // Stream controller for time updates
  final _streamController = StreamController<String>.broadcast();

  PlatformController._() {
    FlutterEventsApi.setUp(
      _FlutterEventsApiImplementation(streamController: _streamController),
    );
  }

  static final PlatformController _platformController = PlatformController._();
  factory PlatformController() => _platformController;

  // Method channel APIs
  Future<String> greeting(String name) async {
    try {
      final request = GreetingRequest()..name = name;
      final response = await _methodsApi.greeting(request);
      return response.message ?? 'No greeting received';
    } catch (e) {
      log('Error while greeting');
      return "";
    }
  }

  Future<int> getBatteryLevel() async {
    try {
      return await _methodsApi.getBatteryLevel();
    } catch (e) {
      log('Error getting battery level: $e');
      return -1;
    }
  }

  // Event channel stream
  Stream<String> get timeUpdatesStream => _streamController.stream;

  void dispose() => _streamController.close();
}

// Implementation of the callback interface for the Flutter side
class _FlutterEventsApiImplementation extends FlutterEventsApi {
  final StreamController<String> streamController;
  _FlutterEventsApiImplementation({required this.streamController});

  @override
  void onTimeUpdate(String time) => streamController.add(time);
}
```

#### Call the native method/event

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';

import '../controllers/platform_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _platformController = PlatformController();
  StreamSubscription<String>? _streamSubscription;
  final ValueNotifier<String> _valueNotifier = ValueNotifier("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform Channels',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Method Channel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final data = await _platformController.greeting("Pigeon");
                if (data.isNotEmpty) {
                  _showSuccess(data);
                } else {
                  _showError("Error Occurred");
                }
              },
              child: const Text('Say hello to platform'),
            ),
            const SizedBox(height: 20, width: double.maxFinite),
            ElevatedButton(
              onPressed: () async {
                final data = await _platformController.getBatteryLevel();
                if (data != -1) {
                  _showSuccess("Battery Level: $data");
                } else {
                  _showError("Error Occurred");
                }
              },
              child: const Text('Show Battery Level'),
            ),
            const SizedBox(height: 50),
            Text(
              'Event Channel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: _valueNotifier,
              builder: (context, value, child) {
                return RichText(
                  text: TextSpan(
                    text: "Time:",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _receiveEvents,
              child: const Text('Receive Events'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopEvents,
              child: const Text('Stop Events'),
            ),
          ],
        ),
      ),
    );
  }

  _receiveEvents() {
    _streamSubscription = _platformController.timeUpdatesStream.listen(
      (event) => _valueNotifier.value = event,
    );
  }

  _stopEvents() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _valueNotifier.value = "";
  }

  _showSuccess(String message) {
    InteractiveToast.slide(
      context,
      title: Text(message),
      trailing: const Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 20,
      ),
    );
  }

  _showError(String message) {
    InteractiveToast.slide(
      context,
      title: Text(message),
      trailing: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
    );
  }
}
```

### ✅ Summary of Benefits

| Feature                        | Traditional Channels            | Pigeon            |
| ------------------------------ | ------------------------------- | ----------------- |
| Summary                        | Pigeon vs. Traditional Channels |                   |
| Manual Channel Setup           | ✅ Required                     | ❌ Not needed     |
| Type-Safe Communication        | ❌ No                           | ✅ Yes            |
| Method & Event Support         | ✅ Yes                          | ✅ Yes            |
| Data Encoding/Decoding         | Manual (Map/JSON)               | ✅ Auto-generated |
| Native Code Generation         | ❌ Manual                       | ✅ Automatic      |
| Flutter ↔ Native Communication | ✅ Supported                    | ✅ Supported      |

## 📎 Tips & Best Practices

- Pigeon supports:
  - Enums
  - Nested objects
  - Nullable types
- Keep `pigeon.dart` clean and minimal: no external imports.
- Re-run the Pigeon command whenever you modify the API contracts.
- Place pigeon definitions in a separate file (`pigeons/pigeon.dart`) to keep code organized.
