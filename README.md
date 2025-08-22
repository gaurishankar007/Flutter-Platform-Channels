# Flutter Platform Channels – Complete Guide

This repository is a complete guide to Flutter Platform Channels, with implementations spread across different branches.

### Branches

*   **`master`:** Provides an introduction to Flutter platform channels with Flutter's default options.

*   **`pigeon_example`:** Guides how to use the Pigeon package for type-safe communication between Flutter and the platform.

*   **`camera_api`:** Provides guidance on how to use the Android and iOS platform-specific camera APIs to integrate camera features like previewing, streaming images/audio, and recording video, using both Flutter's default options and the Pigeon package. This branch also includes camera features for the web platform with the help of the `web` package.

---

This guide on the `master` branch explains how to use the three types of Flutter platform channels:

- ✅ **EventChannel** – For streaming data from native to Flutter
- ✅ **MethodChannel** – For two-way method calls (request → response)
- ✅ **BasicMessageChannel** – For sending messages back and forth without request-response

---

## 📡 EventChannel – Continuous Stream from Native to Flutter

### Flutter Side

```dart
// 1. Define the event channel
static const eventChannel = EventChannel('com.example/stream');

// 2. Start listening
StreamSubscription? _subscription;
void startListening() {
  _subscription = eventChannel.receiveBroadcastStream().listen(
    (event) {
      print("Received: $event");
    },
    onError: (error) {
      print("Error: $error");
    },
  );
}

// 3. Stop listening
void stopListening() {
  _subscription?.cancel();
  _subscription = null;
}
```

- ✅ `receiveBroadcastStream()` starts the connection to the native stream.
- ✅ You **must cancel the stream** to stop receiving events.
- ✅ You can **start again** anytime by calling `receiveBroadcastStream()` again.

### 🔹 Android (Kotlin/Java) Side

```kotlin
class MainActivity : FlutterActivity() {
  private var eventSink: EventChannel.EventSink? = null
  private var timer: Timer? = null

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example/stream")
      .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
          eventSink = events
          timer = Timer()
          timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
              eventSink?.success("Native Event: ${System.currentTimeMillis()}")
            }
          }, 0, 1000)
        }

        override fun onCancel(arguments: Any?) {
          timer?.cancel()
          timer = null
          eventSink = null
        }
      })
  }
}
```

- ✅ `onListen` is triggered when Flutter starts `receiveBroadcastStream()`.
- ✅ `onCancel` is triggered when Flutter cancels the stream.
- ✅ If Flutter restarts listening, `onListen` is called again.

### 🔹 iOS (Swift) Side

```swift
class AppDelegate: FlutterAppDelegate {
  private var eventSink: FlutterEventSink?
  private var timer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let eventChannel = FlutterEventChannel(name: "com.example/stream", binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(StreamHandler())
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class StreamHandler: NSObject, FlutterStreamHandler {
  private var timer: Timer?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      events("Native Event: \(Date().timeIntervalSince1970)")
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    return nil
  }
}
```

- Identical flow to Android.
- `onListen` and `onCancel` handle start/stop of the stream.

### ✅ Summary

| Action            | Flutter                             | Native                          |
| ----------------- | ----------------------------------- | ------------------------------- |
| Start Listening   | `receiveBroadcastStream().listen()` | `onListen()` is triggered       |
| Stop Listening    | `subscription.cancel()`             | `onCancel()` is triggered       |
| Restart Listening | Call `.listen()` again              | `onListen()` is triggered again |

- 🔁 You **can restart** listening after stopping.
- Only **one listener** is active at a time per EventChannel.

## 🔁 MethodChannel – Call Native Methods from Flutter

### Flutter Side

```dart
static const platform = MethodChannel('com.example/method');

Future<void> getBatteryLevel() async {
  try {
    final level = await platform.invokeMethod('getBatteryLevel');
    print("Battery level: $level%");
  } catch (e) {
    print("Failed: $e");
  }
}
```

### Android (Kotlin)

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example/method")
  .setMethodCallHandler { call, result ->
    if (call.method == "getBatteryLevel") {
      val batteryLevel = getBatteryPercentage()
      result.success(batteryLevel)
    } else {
      result.notImplemented()
    }
  }
```

### iOS (Swift)

```swift
MethodChannel(name: "com.example/method", binaryMessenger: controller.binaryMessenger)
  .setMethodCallHandler { call, result in
    if call.method == "getBatteryLevel" {
      result(batteryLevel())
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
```

## 🔁 BasicMessageChannel – Bidirectional Messaging

### Flutter Side

```dart
static const messageChannel = BasicMessageChannel<String>('com.example/message', StringCodec());

void sendMessage() async {
  final reply = await messageChannel.send("Hello from Flutter");
  print("Reply: $reply");
}

void listenForMessages() {
  messageChannel.setMessageHandler((message) async {
    print("Received from native: $message");
    return "Received: $message";
  });
}
```

### Android (Kotlin)

```kotlin
val channel = BasicMessageChannel<String>(messenger, "com.example/message", StringCodec.INSTANCE)

channel.setMessageHandler { message, reply ->
  Log.d("Flutter", "Received: $message")
  reply.reply("Hi Flutter, received: $message")
}
```

### iOS (Swift)

```swift
let channel = FlutterBasicMessageChannel(name: "com.example/message", binaryMessenger: controller.binaryMessenger, codec: FlutterStringCodec.sharedInstance())

channel.setMessageHandler { message, reply in
  print("Received from Flutter: \(message ?? "")")
  reply("Hi Flutter, got: \(message ?? "")")
}
```

## ✅ Summary Table

| Type                | Direction        | Use Case                     |
| ------------------- | ---------------- | ---------------------------- |
| EventChannel        | Native ➡ Flutter | Streams, sensors, timers     |
| MethodChannel       | Flutter ↔ Native | Method calls, requests       |
| BasicMessageChannel | Bidirectional    | Simple messaging, state sync |

## 💡 Notes

- Only one EventChannel listener at a time.
- You can cancel and re-subscribe to EventChannel.
- Always handle errors gracefully.
- Use appropriate codec for BasicMessageChannel (StringCodec, JSONMessageCodec, etc).
