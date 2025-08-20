part of 'web_camera_service.dart';

class WebCameraUtil {
  WebCameraUtil._();

  static Future<bool> isCameraPermissionGranted() async {
    // Check camera permission
    final cameraPermissionDescriptor = {'name': 'camera'}.jsify() as JSObject;
    final cameraPermissionState = await web.window.navigator.permissions
        .query(cameraPermissionDescriptor)
        .toDart;
    return cameraPermissionState.state == 'granted';
  }

  static Future<bool> isMicrophonePermissionGranted() async {
    // Check microphone permission
    final microphonePermissionDescriptor =
        {'name': 'microphone'}.jsify() as JSObject;
    final microphonePermissionState = await web.window.navigator.permissions
        .query(microphonePermissionDescriptor)
        .toDart;
    return microphonePermissionState.state == 'granted';
  }

  static web.MediaStreamConstraints getMediaStreamConstraints(
    WebCameraRequest request,
  ) {
    // Define the desired video settings, including resolution and camera facing mode.
    final videoSetting = {
      "facingMode": request.facingMode,
      "frameRate": request.cameraFrameRate,
      "width": request.cameraSize.width,
      "height": request.cameraSize.height,
    };
    final audioSetting = {
      "sampleRate": 48000, // Preferred sample rate
      "channelCount": 1, // Mono
      "echoCancellation": true,
    };

    // Create media stream constraints, requesting both video (with the defined settings) and audio.
    return web.MediaStreamConstraints(
      video: videoSetting.jsify() as JSObject,
      audio: audioSetting.jsify() as JSObject,
    );
  }

  static WebVideoRecordType getVideoRecordType() {
    final videoMimeTypes = [
      WebVideoRecordType(
        mimeType: 'video/mp4;codecs=h264,aac',
        fileType: "mp4",
      ),
      WebVideoRecordType(
        mimeType: 'video/mp4;codecs=avc1.424028,mp4a.40.2',
        fileType: "mp4",
      ),
      WebVideoRecordType(mimeType: 'video/mp4', fileType: "mp4"),
      WebVideoRecordType(
        mimeType: 'video/webm;codecs=vp9,opus',
        fileType: "webm",
      ),
      WebVideoRecordType(
        mimeType: 'video/webm;codecs=vp8,opus',
        fileType: "webm",
      ),
      WebVideoRecordType(mimeType: 'video/webm', fileType: "webm"),
    ];

    // Find the first supported mp4 type
    final mp4TypeIndex = videoMimeTypes.indexWhere(
      (type) =>
          type.fileType == "mp4" &&
          web.MediaRecorder.isTypeSupported(type.mimeType),
    );
    if (mp4TypeIndex != -1) return videoMimeTypes[mp4TypeIndex];

    // If no supported mp4 type, find any supported type
    return videoMimeTypes.firstWhere(
      (type) => web.MediaRecorder.isTypeSupported(type.mimeType),
      orElse: () => videoMimeTypes.last,
    );
  }
}

/// - [facingMode]: Specifies camera type. 'user' = front camera, 'environment' = back camera.
/// - [cameraFrameRate]: The camera stream in frames per second (FPS).
/// - [cameraSize]: Camera image capture resolution.
class WebCameraRequest {
  final String facingMode;
  final int cameraFrameRate;
  final Size cameraSize;

  const WebCameraRequest({
    required this.facingMode,
    required this.cameraFrameRate,
    required this.cameraSize,
  });
}

/// - [audioBitsPerSecond]: Sets the target bitrate for audio encoding. 128,000 (128 kbps) - standard quality.
/// - [videoBitsPerSecond]: Sets the target bitrate for video encoding. 720p: 1-3 Mbps, 1080p: 3-8 Mbps.
class WebVideoRecordRequest {
  final int audioBitsPerSecond;
  final int videoBitsPerSecond;

  const WebVideoRecordRequest({
    required this.audioBitsPerSecond,
    required this.videoBitsPerSecond,
  });
}

/// - [mimeType]: The MIME type fo the video recording.
/// - [fileType]: The file extension for the video recording.
class WebVideoRecordType {
  final String mimeType;
  final String fileType;

  const WebVideoRecordType({required this.mimeType, required this.fileType});
}
