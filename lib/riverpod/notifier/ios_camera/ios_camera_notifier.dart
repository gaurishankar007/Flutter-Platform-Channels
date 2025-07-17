import 'dart:developer';

import 'package:permission_handler/permission_handler.dart';

import '../../../config/pigeon/generated/ios_camera_api.dart';
import '../../../core/services/ios_camera_service.dart';
import '../../../core/utils/base_notifier/base_state_notifier.dart';

part 'ios_camera_state.dart';

class IOSCameraNotifier extends BaseStateNotifier<IOSCameraState> {
  final IOSCameraService _cameraService;
  int cameraIndex = 1;
  IOSCameraStatus cameraStatus = IOSCameraStatus.unknown;
  bool isStreamingImage = false;
  bool isStreamingAudio = false;
  bool isRecordingVideo = false;

  IOSCameraNotifier({required IOSCameraService cameraService})
    : _cameraService = cameraService,
      super(IOSCameraState.initial());

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

    cameraStatus = IOSCameraStatus.opening;

    final request = IOSCameraRequest(
      cameraIndex: cameraIndex,
      videoInputSize: IOSSize(width: 1920, height: 1080),
      videoInputFrameRate: 30,
      imageStreamFrameSkipInterval: 2,
    );
    final cameraDataState = await _cameraService.openCamera(request);
    if (cameraDataState.hasError) return;

    final cameraData = cameraDataState.data!;
    state = state.copyWith(
      stateStatus: StateStatus.loaded,
      permissionDenied: false,
      textureId: cameraData.textureId,
      previewWidth: cameraData.videoInputSize.width,
      previewHeight: cameraData.videoInputSize.height,
    );
    cameraStatus = IOSCameraStatus.opened;

    log(
      "videoInputSize:(${cameraData.videoInputSize.width}X${cameraData.videoInputSize.height}),"
      " frameRate:${cameraData.videoInputFrameRate}"
      " supportedSizes:${cameraData.supportedSizes.map((e) => "${e.width}x${e.height}, ${e.frameRates}").toString()}",
    );
  }

  Future<void> openSetting() async => await openAppSettings();

  Future<void> switchCamera() async {
    if (isStreamingImage || isStreamingAudio || isRecordingVideo) {
      return;
    }

    state = state.copyWith(stateStatus: StateStatus.loading);
    await closeCamera();
    cameraIndex = cameraIndex == 0 ? 1 : 0;
    await openCamera();
  }

  /// Updates the camera video output orientation and the aspect ratio
  Future<void> updateOrientation() async =>
      await _cameraService.updateCameraVideoOutputOrientation();

  Future<void> startImageStream() async {
    final dataState = await _cameraService.startImageStream();
    if (dataState.hasData) isStreamingImage = true;

    _cameraService.imageStream.listen((imageJpeg) {
      log("Image: ${imageJpeg.length}");
    });
  }

  Future<void> stopImageStream() async {
    final dataState = await _cameraService.stopImageStream();
    if (dataState.hasData) isStreamingImage = false;
  }

  Future<void> startAudioStream() async {
    final dataState = await _cameraService.startAudioStream();
    if (dataState.hasData) isStreamingAudio = true;

    _cameraService.audioStream.listen((audioBytes) {
      log("Audio: ${audioBytes.length}");
    });
  }

  Future<void> stopAudioStream() async {
    final dataState = await _cameraService.stopAudioStream();
    if (dataState.hasData) isStreamingAudio = false;
  }

  Future<void> startVideoRecording() async {
    final dataState = await _cameraService.startVideoRecording();
    if (dataState.hasData) isRecordingVideo = true;
  }

  Future<void> stopVideoRecording() async {
    final dataState = await _cameraService.stopVideoRecording();
    if (dataState.hasData) isRecordingVideo = false;
  }

  Future<void> closeCamera() async {
    cameraStatus = IOSCameraStatus.closing;

    if (isStreamingImage) await stopImageStream();
    if (isStreamingAudio) await stopAudioStream();
    if (isRecordingVideo) await stopVideoRecording();

    await _cameraService.closeCamera();

    state = state.copyWith(stateStatus: StateStatus.loading);
    cameraStatus = IOSCameraStatus.closed;
  }
}
