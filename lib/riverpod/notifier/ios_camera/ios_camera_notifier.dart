import 'dart:async' show StreamSubscription;
import 'dart:developer';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:permission_handler/permission_handler.dart';

import '../../../config/pigeon/generated/ios_camera_api.dart';
import '../../../core/services/ios_camera_service.dart';
import '../../../core/utils/base_notifier/base_state_notifier.dart';

part 'ios_camera_state.dart';

class IOSCameraNotifier extends BaseStateNotifier<IOSCameraState> {
  final IOSCameraService _cameraService;
  int cameraIndex = 1;
  StreamSubscription<Uint8List>? _imageStreamSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
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
      quarterTurns: cameraData.rotationDegrees ~/ 90,
    );

    log(
      "videoInputSize:(${cameraData.videoInputSize.width}X${cameraData.videoInputSize.height}),"
      " frameRate:${cameraData.videoInputFrameRate}"
      " supportedSizes:${cameraData.supportedSizes.map((e) => "${e.width}x${e.height}, ${e.frameRates}").toString()}",
    );
  }

  Future<void> openSetting() async => await openAppSettings();

  Future<void> switchCamera() async {
    if (_imageStreamSubscription != null ||
        _audioStreamSubscription != null ||
        isRecordingVideo) {
      return;
    }

    state = state.copyWith(stateStatus: StateStatus.loading);
    await closeCamera();
    cameraIndex = cameraIndex == 0 ? 1 : 0;
    await openCamera();
  }

  /// Updates the camera video output orientation and the aspect ratio
  Future<void> updateOrientation() async {
    final dataState = await _cameraService.updateCameraVideoOutputOrientation();
    if (dataState.hasError) return;

    state = state.copyWith(quarterTurns: dataState.data! ~/ 90);
  }

  Future<void> startImageStream() async {
    final dataState = await _cameraService.startImageStream();
    if (dataState.hasData) {
      _imageStreamSubscription = _cameraService.imageStream.listen((imageJpeg) {
        log("Image: ${imageJpeg.length}");
      });
    }
  }

  Future<void> stopImageStream() async {
    await _cameraService.stopImageStream();
    _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
  }

  Future<void> startAudioStream() async {
    final dataState = await _cameraService.startAudioStream();
    if (dataState.hasData) {
      _audioStreamSubscription = _cameraService.audioStream.listen((
        audioBytes,
      ) {
        log("Audio: ${audioBytes.length}");
      });
    }
  }

  Future<void> stopAudioStream() async {
    await _cameraService.stopAudioStream();
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
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
    if (_imageStreamSubscription != null) await stopImageStream();
    if (_audioStreamSubscription != null) await stopAudioStream();
    if (isRecordingVideo) await stopVideoRecording();

    await _cameraService.closeCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      state = state.copyWith(stateStatus: StateStatus.loading);
    });
  }
}
