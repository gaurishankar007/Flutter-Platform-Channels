import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/pigeon/generated/android_camera_api.dart';
import '../data/errors/data_handler.dart';
import '../data/states/data_state.dart';
import '../utils/type_defs.dart';

abstract class AndroidCameraService {
  FutureBool checkCameraPermissions();
  FutureData<AndroidCameraData> openCamera(AndroidCameraRequest request);
  FutureData<AndroidOrientationData> getOrientationData();
  FutureNull startImageStream(AndroidImageStreamRequest request);
  Stream<AndroidCameraImageData> get imageStream;
  FutureNull stopImageStream();
  FutureNull startAudioStream(AndroidAudioStreamRequest request);
  Stream<Uint8List> get audioStream;
  FutureNull stopAudioStream();
  FutureNull startVideoRecording(AndroidVideoRecordRequest request);
  FutureNull stopVideoRecording();
  FutureNull closeCamera();
}

@module
abstract class AndroidCameraHostApiModule {
  @lazySingleton
  AndroidCameraHostApi get cameraHostApi => AndroidCameraHostApi();
}

@LazySingleton(as: AndroidCameraService)
class AndroidCameraServiceImpl implements AndroidCameraService {
  final AndroidCameraHostApi _cameraHostApi;
  final _imageStreamController =
      StreamController<AndroidCameraImageData>.broadcast();
  final _audioStreamController = StreamController<Uint8List>.broadcast();

  AndroidCameraServiceImpl({required AndroidCameraHostApi cameraHostApi})
    : _cameraHostApi = cameraHostApi {
    AndroidCameraFlutterApi.setUp(
      _AndroidCameraFlutterApiImpl(
        imageStreamController: _imageStreamController,
        audioStreamController: _audioStreamController,
      ),
    );
  }

  @override
  FutureBool checkCameraPermissions() {
    return ErrorHandler.handleException(() async {
      bool isCameraPermissionGranted = await Permission.camera.isGranted;
      bool isMicrophonePermissionGranted =
          await Permission.microphone.isGranted;

      if (!isCameraPermissionGranted) {
        final cameraPermissionStatus = await Permission.camera.request();
        isCameraPermissionGranted =
            cameraPermissionStatus == PermissionStatus.granted;
      }

      if (!isMicrophonePermissionGranted) {
        final microphonePermissionStatus = await Permission.microphone
            .request();
        isMicrophonePermissionGranted =
            microphonePermissionStatus == PermissionStatus.granted;
      }

      return SuccessState(
        data: isCameraPermissionGranted && isMicrophonePermissionGranted,
      );
    });
  }

  @override
  FutureData<AndroidCameraData> openCamera(AndroidCameraRequest request) {
    return ErrorHandler.handleException(() async {
      final cameraData = await _cameraHostApi.openCamera(request);
      return SuccessState(data: cameraData);
    });
  }

  @override
  FutureData<AndroidOrientationData> getOrientationData() {
    return ErrorHandler.handleException(() async {
      final orientationData = await _cameraHostApi.getOrientationData();
      return SuccessState(data: orientationData);
    });
  }

  @override
  FutureNull startImageStream(AndroidImageStreamRequest request) {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.startImageStream(request);
      return SuccessNullState();
    });
  }

  @override
  Stream<AndroidCameraImageData> get imageStream =>
      _imageStreamController.stream;

  @override
  FutureNull stopImageStream() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.stopImageStream();
      return SuccessNullState();
    });
  }

  @override
  FutureNull startAudioStream(AndroidAudioStreamRequest request) {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.startAudioStream(request);
      return SuccessNullState();
    });
  }

  @override
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  @override
  FutureNull stopAudioStream() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.stopAudioStream();
      return SuccessNullState();
    });
  }

  @override
  FutureNull startVideoRecording(AndroidVideoRecordRequest request) {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.startVideoRecording(request);
      return SuccessNullState();
    });
  }

  @override
  FutureNull stopVideoRecording() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.stopVideoRecording();
      return SuccessNullState();
    });
  }

  @override
  FutureNull closeCamera() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.closeCamera();
      return SuccessNullState();
    });
  }
}

// Implementation of the callback interface for the Flutter side
class _AndroidCameraFlutterApiImpl extends AndroidCameraFlutterApi {
  final StreamController<AndroidCameraImageData> _imageStreamController;
  final StreamController<Uint8List> _audioStreamController;

  _AndroidCameraFlutterApiImpl({
    required StreamController<AndroidCameraImageData> imageStreamController,
    required StreamController<Uint8List> audioStreamController,
  }) : _imageStreamController = imageStreamController,
       _audioStreamController = audioStreamController;

  @override
  void onImageReceived(AndroidCameraImageData cameraImage) =>
      _imageStreamController.add(cameraImage);

  @override
  void onAudioReceived(Uint8List audioBytes) =>
      _audioStreamController.add(audioBytes);
}
