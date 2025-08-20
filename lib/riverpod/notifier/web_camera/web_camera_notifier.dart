import 'dart:async' show StreamSubscription;
import 'dart:developer' show log;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Size;

import 'package:flutter/widgets.dart' show WidgetsBinding;

import '../../../core/services/web_camera//web_camera_service.dart';
import '../../../core/utils/base_notifier/base_state_notifier.dart';

part 'web_camera_state.dart';

class WebCameraNotifier extends BaseStateNotifier<WebCameraState> {
  final WebCameraService _cameraService;
  StreamSubscription<Uint8List>? _imageStreamSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  bool isRecordingVideo = false;

  WebCameraNotifier({required WebCameraService cameraService})
    : _cameraService = cameraService,
      super(WebCameraState.initial());

  Future<void> openCamera() async {
    final request = WebCameraRequest(
      facingMode: "user",
      cameraFrameRate: 30,
      cameraSize: Size(1920, 1080),
    );
    final cameraState = await _cameraService.openCamera(request);

    final permissionState = await _cameraService.checkCameraPermissions();
    final isPermissionDenied = permissionState.data != true;

    if (isPermissionDenied) {
      state = state.copyWith(
        stateStatus: StateStatus.loaded,
        permissionDenied: true,
      );
    } else if (cameraState.hasData) {
      state = state.copyWith(
        stateStatus: StateStatus.loaded,
        permissionDenied: false,
        htmlElementType: cameraState.data,
      );
    }
  }

  Future<void> startImageStream() async {
    final dataState = await _cameraService.startImageStream(frameRate: 15);
    if (dataState.hasData) {
      _imageStreamSubscription = _cameraService.imageStream.listen((
        imageBytes,
      ) {
        log("Image: ${imageBytes.length} bytes received");
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
        log("Audio: ${audioBytes.length} bytes received");
      });
    }
  }

  Future<void> stopAudioStream() async {
    await _cameraService.stopAudioStream();
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
  }

  Future<void> startVideoRecording() async {
    final request = WebVideoRecordRequest(
      audioBitsPerSecond: 256000, // 256 kbps audio
      videoBitsPerSecond: 8000000, // 8 Mbps video
    );
    final dataState = await _cameraService.startVideoRecording(request);
    if (dataState.hasData) isRecordingVideo = true;
  }

  Future<void> stopVideoRecording() async {
    final dataState = await _cameraService.stopVideoRecording();
    if (dataState.hasData) {
      isRecordingVideo = false;
      _cameraService.saveBlobToDownloads();
    }
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
