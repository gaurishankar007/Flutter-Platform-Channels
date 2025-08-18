// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: depend_on_referenced_packages

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/config/pigeon/generated/ios_camera_api.dart',
    swiftOut: 'ios/Runner/IOSCameraApi.swift',
    dartPackageName: 'com.platform.channel',
  ),
)
@HostApi()
abstract class IOSCameraHostApi {
  @async
  bool requestCameraAccess();

  @async
  bool requestMicrophoneAccess();

  @async
  IOSCameraData openCamera(IOSCameraRequest request);

  @async
  int updateCameraVideoOutputOrientation();

  @async
  bool startVideoRecording();

  @async
  bool stopVideoRecording();

  @async
  bool closeCamera();
}

/// Specifies the parameters for opening the camera
/// - [cameraIndex]: Camera selection index (e.g., 0 for back, 1 for front)
/// - [videoInputSize]: Camera capture resolution
/// - [videoInputFrameRate]: Camera capture frame rate
/// - [imageStreamFrameSkipInterval]: The interval between sending image frames while streaming image.
/// Camera frame rate = 30fps, [imageStreamFrameSkipInterval] = 2, Image stream rate = 15fps, (30 / 2).
class IOSCameraRequest {
  final int cameraIndex;
  final IOSSize videoInputSize;
  final int videoInputFrameRate;
  final int imageStreamFrameSkipInterval;

  const IOSCameraRequest({
    required this.cameraIndex,
    required this.videoInputSize,
    required this.videoInputFrameRate,
    required this.imageStreamFrameSkipInterval,
  });
}

/// Stores the camera data while opening the camera
/// - [textureId]: Surface texture id.
/// - [videoInputSize]: Camera capture resolution
/// - [videoInputFrameRate]: Camera capture frame rate
/// - [supportedSizes]: Supported sizes along with it's frame rates by the camera device.
/// - [rotationDegrees]: Camera preview rotation degrees for accurate preview.
class IOSCameraData {
  final int textureId;
  final IOSSize videoInputSize;
  final int videoInputFrameRate;
  final List<IOSCameraSize> supportedSizes;
  final int rotationDegrees;

  const IOSCameraData({
    required this.textureId,
    required this.videoInputSize,
    required this.videoInputFrameRate,
    required this.supportedSizes,
    required this.rotationDegrees,
  });
}

/// - [width]: Width of the size.
/// - [height]: Height of the size.
/// - [frameRates]: Supported frame rates.
class IOSCameraSize {
  final double width;
  final double height;
  final List<int> frameRates;

  const IOSCameraSize({
    required this.width,
    required this.height,
    required this.frameRates,
  });
}

class IOSSize {
  final double width;
  final double height;

  const IOSSize({required this.width, required this.height});
}

class IOSRangeInt {
  final int lower;
  final int upper;

  const IOSRangeInt({required this.lower, required this.upper});
}
