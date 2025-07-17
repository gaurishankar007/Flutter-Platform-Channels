# 📸 Flutter Platform Channels with Pigeon for Camera APIs

This project demonstrates how to use **[Pigeon](https://pub.dev/packages/pigeon)** to create type-safe, structured communication between Flutter and native code for accessing camera features on both Android and iOS.

## 🚀 Features

- **Camera Preview:** Display a live camera preview from the native camera.
- **Image Streaming:** Stream camera frames from the native platform to Flutter.
- **Audio Streaming:** Stream audio from the microphone.
- **Video Recording:** Record videos using the native camera.
- **Permission Handling:** Request camera and microphone permissions.
- **Type-Safe APIs:** All communication between Flutter and native code is type-safe, thanks to Pigeon.

## 🧰 Tech Stack

- **Flutter:** For the cross-platform UI.
- **Pigeon:** For generating the platform channel code.
- **Riverpod:** For state management.
- **GetIt & Injectable:** For dependency injection.

## 🐦 Pigeon Configuration

Pigeon is used to define the communication interface between Flutter and the native platforms. The API contracts are defined in Dart files, and Pigeon generates the corresponding Dart, Kotlin, and Swift code.

### Android Camera API (`lib/config/pigeon/android_camera_api_config.dart`)

```dart
@HostApi()
abstract class AndroidCameraHostApi {
  @async
  AndroidCameraData openCamera(AndroidCameraRequest request);

  @async
  void startImageStream(AndroidImageStreamRequest request);

  @async
  void stopImageStream();

  // ... other methods
}

@FlutterApi()
abstract class AndroidCameraFlutterApi {
  void onImageReceived(AndroidCameraImageData cameraImage);
  void onAudioReceived(Uint8List audioBytes);
}
```

### iOS Camera API (`lib/config/pigeon/ios_camera_api_config.dart`)

```dart
@HostApi()
abstract class IOSCameraHostApi {
  @async
  bool requestCameraAccess();

  @async
  IOSCameraData openCamera(IOSCameraRequest request);

  @async
  bool startVideoRecording();

  @async
  bool stopVideoRecording();

  // ... other methods
}
```

To generate the code, run the following command:

```sh
dart run pigeon --input lib/config/pigeon/android_camera_api_config.dart
dart run pigeon --input lib/config/pigeon/ios_camera_api_config.dart
```

## 📱 Native Implementation

The generated Pigeon code is implemented on the native side to provide the actual camera functionality.

### Android (`android/app/src/main/kotlin/com/example/platform_channel/MainActivity.kt`)

The `MainActivity.kt` file implements the `AndroidCameraHostApi` interface to control the camera using CameraX.

### iOS (`ios/Runner/AppDelegate.swift`)

The `AppDelegate.swift` file implements the `IOSCameraHostApi` interface to control the camera using AVFoundation.

## 💻 Flutter Implementation

On the Flutter side, services are used to abstract the platform channel communication.

### Camera Services

-   **`AndroidCameraService`:** Interacts with the `AndroidCameraHostApi` to control the camera on Android.
-   **`IOSCameraService`:** Interacts with the `IOSCameraHostApi` to control the camera on iOS.

### Camera View

The `CameraView` widget uses the appropriate camera service based on the platform to display the camera preview and provide controls for starting/stopping streaming and recording.

```dart
class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (Platform.isAndroid)
                AndroidCameraWidget()
              else if (Platform.isIOS)
                IOSCameraWidget(),
              // ... action buttons
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🚀 How to Run

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/gaurishankar007/Flutter-Platform-Channels.git
    ```
2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
3.  **Generate Pigeon code:**
    ```sh
    dart run pigeon --input lib/config/pigeon/android_camera_api_config.dart
    dart run pigeon --input lib/config/pigeon/ios_camera_api_config.dart
    ```
4.  **Run the app:**
    ```sh
    flutter run
    ```