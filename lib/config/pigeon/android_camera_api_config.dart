// ignore_for_file: depend_on_referenced_packages

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/config/pigeon/generated/android_camera_api.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/platform_channel/AndroidCameraApi.kt',
    dartPackageName: 'com.platform.channel',
  ),
)
@HostApi()
abstract class AndroidCameraHostApi {
  @async
  AndroidCameraData openCamera(AndroidCameraRequest request);

  @async
  AndroidOrientationData getOrientationData();

  @async
  void startImageStream(AndroidImageStreamRequest request);

  @async
  void stopImageStream();

  @async
  void startAudioStream(AndroidAudioStreamRequest request);

  @async
  void stopAudioStream();

  @async
  void startVideoRecording(AndroidVideoRecordRequest request);

  @async
  void stopVideoRecording();

  @async
  void closeCamera();
}

@FlutterApi()
abstract class AndroidCameraFlutterApi {
  /// Receives image data from the camera while streaming images.
  void onImageReceived(AndroidCameraImageData cameraImage);

  /// Receives audio bytes from the microphone while streaming audio.
  void onAudioReceived(Uint8List audioBytes);
}

/// Specifies the parameters for opening the camera
/// - [cameraIndex]: Camera selection index (e.g., 0 for back, 1 for front)
/// - [videoSize]: Resolution for image streaming and video recording. (e.g., "1920x1080")
/// - [videoFrameRate]: Frame rate at which the camera session captures the images (e.g., 30, 60)
/// - [imageStreamFormat]: The format at which image will be streamed like "YUV_420_888", "RGB_565", "JPEG",
class AndroidCameraRequest {
  final int cameraIndex;
  final AndroidSize videoSize;
  final int videoFrameRate;
  final String imageStreamFormat;

  const AndroidCameraRequest({
    required this.cameraIndex,
    required this.videoSize,
    required this.videoFrameRate,
    required this.imageStreamFormat,
  });
}

/// - [frameSkipInterval]: The interval between sending image frames while streaming image.
/// Camera frame rate = 30fps, [frameSkipInterval] = 2, Image stream rate = 15fps (30 / 2).
class AndroidImageStreamRequest {
  final int frameSkipInterval;

  const AndroidImageStreamRequest({required this.frameSkipInterval});
}

/// - [bufferSizeKB]: The size of the audio bytes in KB which will be steamed. e.g. 8KB = 8x1024 bytes.
/// - [sampleRate]: Audio samples are taken per second. 44100 (44.1KHz) or 48000 (48KHz).
class AndroidAudioStreamRequest {
  final int bufferSizeKB;
  final int sampleRate;

  const AndroidAudioStreamRequest({
    required this.bufferSizeKB,
    required this.sampleRate,
  });
}

/// - [filePath]: Path of the video file where it will be saved. e.g. /storage/emulated/0/Download/video.mp4.
/// - [encodingBitRate]: Data (bits) used to represent the video per second. For 720p = 2-5 Mbps, 1080p = 5-10 Mbps, 2160p = 15-30 Mbps. 1MB = 1000000 Bit
/// - [audioChannels]: Number of audio channels. 1 for mono and 2 for stereo if supported.
/// - [audioSampleRate]: Audio samples are taken per second. 44100 (44.1KHz) or 48000 (48KHz).
/// - [audioEncodingBitRate]: Data (bits) is used to represent the audio per second. Higher is better better audio quality. Common values for good quality AAC audio are 96 kbps, 128 kbps, or even 192 kbps.
class AndroidVideoRecordRequest {
  final String filePath;
  final int encodingBitRate;
  final int audioChannels;
  final int audioSampleRate;
  final int audioEncodingBitRate;

  const AndroidVideoRecordRequest({
    required this.filePath,
    required this.encodingBitRate,
    required this.audioChannels,
    required this.audioSampleRate,
    required this.audioEncodingBitRate,
  });
}

/// Stores the camera data while opening the camera
/// - [textureId]: Surface texture id.
/// - [videoSize]: Resolution for image streaming and video recording.
/// - [videoFrameRate]: Frame rate at which the camera session captures the images.
/// - [supportedSizes]: Supported resolutions by the camera device.
/// - [supportedFps]: Supported frame rates by the camera device.
class AndroidCameraData {
  final int textureId;
  final AndroidSize videoSize;
  final int videoFrameRate;
  final List<AndroidSize> supportedSizes;
  final List<int> supportedFps;

  const AndroidCameraData({
    required this.videoFrameRate,
    required this.textureId,
    required this.videoSize,
    required this.supportedSizes,
    required this.supportedFps,
  });
}

class AndroidOrientationData {
  final int sensorOrientationDegrees;
  final int deviceOrientationDegrees;
  final int displayOrientationDegrees;
  final int rotationDegrees;

  const AndroidOrientationData({
    required this.sensorOrientationDegrees,
    required this.deviceOrientationDegrees,
    required this.displayOrientationDegrees,
    required this.rotationDegrees,
  });
}

class AndroidImagePlaneData {
  final Uint8List bytes;
  final int rowStride;
  final int pixelStride;

  const AndroidImagePlaneData({
    required this.bytes,
    required this.rowStride,
    required this.pixelStride,
  });
}

class AndroidCameraImageData {
  final int width;
  final int height;
  final int format;
  final List<AndroidImagePlaneData?> planes;
  final int rotationDegrees;

  const AndroidCameraImageData({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    required this.rotationDegrees,
  });
}

class AndroidSize {
  final double width;
  final double height;

  const AndroidSize({required this.width, required this.height});
}

class AndroidRangeInt {
  final int lower;
  final int upper;

  const AndroidRangeInt({required this.lower, required this.upper});
}
