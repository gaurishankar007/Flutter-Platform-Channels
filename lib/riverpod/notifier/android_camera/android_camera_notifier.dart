import 'dart:async' show StreamSubscription;
import 'dart:developer';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../config/pigeon/generated/android_camera_api.dart';
import '../../../core/services/android_camera_service.dart';
import '../../../core/utils/base_notifier/base_state_notifier.dart';
import '../../../core/utils/file_picker_util.dart';

part 'android_camera_state.dart';

class AndroidCameraNotifier extends BaseStateNotifier<CameraState> {
  final AndroidCameraService _cameraService;
  int cameraIndex = 1;
  AndroidCameraStatus cameraStatus = AndroidCameraStatus.unknown;
  StreamSubscription<AndroidCameraImageData>? _imageStreamSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  String videoRecordDirectory = "";
  bool isVideoRecording = false;

  AndroidCameraNotifier({required AndroidCameraService cameraService})
    : _cameraService = cameraService,
      super(CameraState.initial());

  /// Open the camera and get camera details
  Future<void> openCamera() async {
    // Check for camera permissions
    final permissionState = await _cameraService.checkCameraPermissions();
    if (permissionState.hasError) return;
    // If the permissions are not granted
    if (!permissionState.data!) {
      state = state.copyWith(
        stateStatus: StateStatus.loaded,
        permissionDenied: true,
      );
      return;
    }

    cameraStatus = AndroidCameraStatus.opening;

    final request = AndroidCameraRequest(
      cameraIndex: cameraIndex,
      cameraFrameRate: 30,
      previewSize: AndroidSize(width: 1920, height: 1080),
    );
    final cameraState = await _cameraService.openCamera(request);
    if (cameraState.hasError) return;

    final cameraData = cameraState.data!;
    CameraState notifierState = state.copyWith(
      stateStatus: StateStatus.loaded,
      permissionDenied: false,
      textureId: cameraData.textureId,
      previewWidth: cameraData.previewSize.width,
      previewHeight: cameraData.previewSize.height,
    );

    // Get orientation details
    final orientationState = await _cameraService.getOrientationData();
    if (orientationState.hasData) {
      final rotationDegrees = orientationState.data!.displayOrientationDegrees;
      notifierState = notifierState.copyWith(
        quarterTurns: (rotationDegrees / 90).toInt(),
      );
    }

    // Update UI State
    state = notifierState;
    cameraStatus = AndroidCameraStatus.opened;

    log(
      "PreviewSize:(${cameraData.previewSize.width}X${cameraData.previewSize.height}),"
      " Fps:${cameraData.frameRate},"
      " supportedSizes:(${cameraData.supportedSizes.map((e) => "${e.width}x${e.height}, ").toString()})"
      " supportedFPS:(${cameraData.supportedFps})",
    );
  }

  Future<void> switchCamera() async {
    if (_imageStreamSubscription != null) {
      return;
    } else if (_audioStreamSubscription != null) {
      return;
    } else if (isVideoRecording) {
      return;
    }

    state = state.copyWith(stateStatus: StateStatus.loading);
    await closeCamera();
    cameraIndex = cameraIndex == 0 ? 1 : 0;
    await openCamera();
  }

  /// - Android: Rotates the camera preview
  /// - IOS: Updates the camera video output orientation and the aspect ratio
  Future<void> updateOrientation() async {
    final dataState = await _cameraService.getOrientationData();
    if (dataState.hasData) {
      final rotationDegrees = dataState.data!.displayOrientationDegrees;
      state = state.copyWith(quarterTurns: (rotationDegrees / 90).toInt());
      log(
        "isFrontCamera:${dataState.data!.isFrontCamera}"
        " sensor:${dataState.data!.sensorOrientationDegrees},"
        " device:${dataState.data!.deviceOrientationDegrees},"
        " display:${dataState.data!.displayOrientationDegrees}.",
      );
    }
  }

  Future<void> saveImage(Uint8List imageBytes) async {
    final fileName = "${DateTime.now().millisecondsSinceEpoch}_image.jpg";
    final filePath = "/storage/emulated/0/Download/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
  }

  Uint8List yuv420ToJpeg(AndroidCameraImageData cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0]!.bytes;
    final uPlane = cameraImage.planes[1]!.bytes;
    final vPlane = cameraImage.planes[2]!.bytes;
    final yRowStride = cameraImage.planes[0]!.rowStride;
    final uvRowStride = cameraImage.planes[1]!.rowStride;
    final uvPixelStride = cameraImage.planes[1]!.pixelStride;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        final Y = yPlane[yIndex];
        final U = uPlane[uvIndex];
        final V = vPlane[uvIndex];

        // YUV to RGB conversion
        int r = (Y + 1.370705 * (V - 128)).round();
        int g = (Y - 0.337633 * (U - 128) - 0.698001 * (V - 128)).round();
        int b = (Y + 1.732446 * (U - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    // Apply rotation if needed
    img.Image rotatedImage = rgbImage;
    if (cameraImage.rotationDegrees != 0) {
      rotatedImage = img.copyRotate(
        rgbImage,
        angle: cameraImage.rotationDegrees,
      );
    }

    return Uint8List.fromList(img.encodeJpg(rotatedImage));
  }

  Future<void> startImageStream() async {
    final request = AndroidImageStreamRequest(
      frameSkipInterval: 6,
      imageSize: AndroidSize(width: 1920, height: 1080),
    );
    await _cameraService.startImageStream(request);
    _imageStreamSubscription = _cameraService.imageStream.listen((
      cameraImage,
    ) async {
      log(
        "Image: ${cameraImage.width}x${cameraImage.height}, ${cameraImage.rotationDegrees}",
      );
    });
  }

  Future<void> stopImageStream() async {
    await _cameraService.stopImageStream();
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
  }

  Future<void> startAudioStream() async {
    final request = AndroidAudioStreamRequest(
      bufferSizeKB: 16, // 16Kb
      sampleRate: 48000, // 48KHz
    );
    await _cameraService.startAudioStream(request);
    _audioStreamSubscription = _cameraService.audioStream.listen((audioBytes) {
      log("Audio: ${audioBytes.length} bytes received");
    });
  }

  Future<void> stopAudioStream() async {
    await _cameraService.stopAudioStream();
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
  }

  Future<void> pickUpVideoLocation() async {
    videoRecordDirectory = await FilePickerUtil.pickDirectory() ?? "";
  }

  Future<void> startVideoRecording() async {
    if (videoRecordDirectory.isEmpty) {
      /// Create application cache directory if does not exist
      final cacheDirectory = await getApplicationCacheDirectory();
      if (cacheDirectory.existsSync()) {
        await cacheDirectory.create(recursive: true);
      }
      videoRecordDirectory = cacheDirectory.path;
    }

    final fileName = "${DateTime.now().millisecondsSinceEpoch}_video.mp4";
    final request = AndroidVideoRecordRequest(
      filePath: "/storage/emulated/0/Download/$fileName",
      resolution: AndroidSize(width: 1920, height: 1080),
      encodingBitRate: 10000000, // 10Mbps
      audioChannels: 1,
      audioSampleRate: 48000, // 48KHz
      audioEncodingBitRate: 128000, // 128Kbps
    );
    final dataState = await _cameraService.startVideoRecording(request);
    if (dataState.hasData) isVideoRecording = true;
  }

  Future<void> stopVideoRecording() async {
    final dataState = await _cameraService.stopVideoRecording();
    if (dataState.hasData) isVideoRecording = false;
  }

  Future<void> closeCamera() async {
    cameraStatus = AndroidCameraStatus.closing;

    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    await _cameraService.closeCamera();

    cameraStatus = AndroidCameraStatus.closed;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state = state.copyWith(stateStatus: StateStatus.loading);
    });
  }

  // Android: Closes and opens the camera when the app goes in and out of the background
  Future<void> manageLifeCycle(AppLifecycleState appLifeCycleState) async {
    final isCameraClosable =
        cameraStatus == AndroidCameraStatus.opened &&
        (appLifeCycleState == AppLifecycleState.inactive ||
            appLifeCycleState == AppLifecycleState.paused);
    final isCameraOpenable =
        cameraStatus == AndroidCameraStatus.closed &&
        appLifeCycleState == AppLifecycleState.resumed;

    if (isCameraClosable) {
      closeCamera();
    } else if (isCameraOpenable) {
      openCamera();
    }
  }
}
