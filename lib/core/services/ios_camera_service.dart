import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../config/pigeon/generated/ios_camera_api.dart';
import '../data/errors/data_handler.dart';
import '../data/states/data_state.dart';
import '../utils/type_defs.dart';

abstract class IOSCameraService {
  FutureBool checkCameraPermissions();
  FutureData<IOSCameraData> openCamera(IOSCameraRequest request);
  FutureInt updateCameraVideoOutputOrientation();
  FutureNull startImageStream();
  Stream<Uint8List> get imageStream;
  FutureNull stopImageStream();
  FutureNull startAudioStream();
  Stream<Uint8List> get audioStream;
  FutureNull stopAudioStream();
  FutureNull startVideoRecording();
  FutureNull stopVideoRecording();
  FutureNull closeCamera();
}

@module
abstract class IOSCameraHostApiModule {
  @lazySingleton
  IOSCameraHostApi get cameraHostApi => IOSCameraHostApi();
}

@LazySingleton(as: IOSCameraService)
class IOSCameraServiceImpl implements IOSCameraService {
  final IOSCameraHostApi _cameraHostApi;

  final _imageStreamChannel = EventChannel("app.vaiolin.ai/image_stream");
  final _imageStreamController = StreamController<Uint8List>.broadcast();
  StreamSubscription? _imageStreamSubscription;

  final _audioStreamChannel = EventChannel("app.vaiolin.ai/audio_stream");
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  StreamSubscription? _audioStreamSubscription;

  IOSCameraServiceImpl({required IOSCameraHostApi cameraHostApi})
    : _cameraHostApi = cameraHostApi;

  @override
  FutureBool checkCameraPermissions() {
    return ErrorHandler.handleException(() async {
      bool isCameraPermissionGranted = await _cameraHostApi
          .requestCameraAccess();
      bool isMicrophonePermissionGranted = await _cameraHostApi
          .requestMicrophoneAccess();

      return SuccessState(
        data: isCameraPermissionGranted && isMicrophonePermissionGranted,
      );
    });
  }

  @override
  FutureData<IOSCameraData> openCamera(IOSCameraRequest request) {
    return ErrorHandler.handleException(() async {
      final cameraIOSData = await _cameraHostApi.openCamera(request);
      return SuccessState(data: cameraIOSData);
    });
  }

  @override
  FutureInt updateCameraVideoOutputOrientation() {
    return ErrorHandler.handleException(() async {
      final rotationDegrees = await _cameraHostApi
          .updateCameraVideoOutputOrientation();
      return SuccessState(data: rotationDegrees);
    });
  }

  @override
  FutureNull startImageStream() {
    return ErrorHandler.handleException(() async {
      _imageStreamSubscription ??= _imageStreamChannel
          .receiveBroadcastStream()
          .listen((dynamic imageData) {
            _imageStreamController.add(imageData as Uint8List);
          });

      return SuccessState.nil;
    });
  }

  @override
  Stream<Uint8List> get imageStream => _imageStreamController.stream;

  @override
  FutureNull stopImageStream() {
    return ErrorHandler.handleException(() async {
      await _imageStreamSubscription?.cancel();
      _imageStreamSubscription = null;
      return SuccessState.nil;
    });
  }

  @override
  FutureNull startAudioStream() {
    return ErrorHandler.handleException(() async {
      _audioStreamSubscription ??= _audioStreamChannel
          .receiveBroadcastStream()
          .listen((dynamic audioData) {
            _audioStreamController.add(audioData as Uint8List);
          });

      return SuccessState.nil;
    });
  }

  @override
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  @override
  FutureNull stopAudioStream() {
    return ErrorHandler.handleException(() async {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      return SuccessState.nil;
    });
  }

  @override
  FutureNull startVideoRecording() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.startVideoRecording();
      return SuccessState.nil;
    });
  }

  @override
  FutureNull stopVideoRecording() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.stopVideoRecording();
      return SuccessState.nil;
    });
  }

  @override
  FutureNull closeCamera() {
    return ErrorHandler.handleException(() async {
      await _cameraHostApi.closeCamera();
      return SuccessState.nil;
    });
  }
}