import 'dart:async';
import 'dart:convert' show base64Decode;
import 'dart:js_interop';
import 'dart:typed_data' show Uint8List, ByteData;
import 'dart:ui' show Size;
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart' show Endian;
import 'package:web/web.dart' as web;

import '../../data/errors/data_handler.dart';
import '../../data/states/data_state.dart';
import '../../utils/type_defs.dart';

part 'web_camera_util.dart';

abstract class WebCameraService {
  FutureBool checkCameraPermissions();
  Future<DataState<String>> openCamera(WebCameraRequest request);
  FutureNull startImageStream({required int frameRate});
  Stream<Uint8List> get imageStream;
  FutureNull stopImageStream();
  FutureNull startAudioStream();
  Stream<Uint8List> get audioStream;
  FutureNull stopAudioStream();
  FutureNull startVideoRecording(WebVideoRecordRequest request);
  FutureNull stopVideoRecording();
  FutureNull saveBlobToDownloads();
  FutureNull closeCamera();
}

class WebCameraServiceImpl implements WebCameraService {
  web.MediaStream? _cameraStream;
  web.HTMLVideoElement? _videoElement;

  // Image streaming related properties
  final _imageStreamController = StreamController<Uint8List>.broadcast();
  Timer? _frameTimer;
  web.HTMLCanvasElement? _canvasElement;
  web.CanvasRenderingContext2D? _canvasContext;

  // Audio streaming related properties
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  web.AudioContext? _audioContext;
  web.ScriptProcessorNode? _scriptProcessor;

  // Video recording related properties
  web.MediaRecorder? _mediaRecorder;
  List<web.Blob> _recordedBlobs = [];
  WebVideoRecordType _videoRecordType = WebVideoRecordType(
    mimeType: 'video/webm',
    fileType: "webm",
  );

  @override
  FutureBool checkCameraPermissions() {
    return ErrorHandler.handleException(() async {
      final permissionStatus = await Future.wait([
        WebCameraUtil.isCameraPermissionGranted(),
        WebCameraUtil.isMicrophonePermissionGranted(),
      ]);
      final isPermissionGranted = permissionStatus.reduce((a, b) => a && b);

      return SuccessState(data: isPermissionGranted);
    });
  }

  @override
  Future<DataState<String>> openCamera(WebCameraRequest request) {
    return ErrorHandler.handleException(() async {
      final constraints = WebCameraUtil.getMediaStreamConstraints(request);

      // Request access to the user's camera and microphone.
      // This will trigger a permission prompt in the browser if not already granted.
      _cameraStream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      // Configure the video element styles for camera preview.
      _videoElement = web.HTMLVideoElement()
        ..srcObject = _cameraStream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..autoplay = true
        ..muted = true; // Don't provide output audio in the video element.

      // Register the factory with the unique view type for camera preview.
      final htmlElementType =
          'cameraPreview-${DateTime.now().microsecondsSinceEpoch}';
      ui.platformViewRegistry.registerViewFactory(
        htmlElementType,
        (int viewId) => _videoElement!,
      );

      _videoRecordType = WebCameraUtil.getVideoRecordType();

      return SuccessState(data: htmlElementType);
    });
  }

  @override
  FutureNull startImageStream({required int frameRate}) {
    return ErrorHandler.handleException(() async {
      if (_cameraStream == null || _videoElement == null) {
        return FailureState(message: 'Camera stream is not initialized.');
      }

      // Create a canvas element to draw video frames.
      _canvasElement = web.HTMLCanvasElement();
      _canvasContext = _canvasElement!.context2D;
      // Set canvas size to match video
      _canvasElement!.width = _videoElement!.videoWidth;
      _canvasElement!.height = _videoElement!.videoHeight;

      // Start a timer to capture frames at the specified frame rate.
      final duration = Duration(milliseconds: 1000 ~/ frameRate);
      _frameTimer = Timer.periodic(duration, (_) {
        _canvasContext?.drawImage(_videoElement!, 0, 0);

        final encodedImageData = _canvasElement!
            .toDataUrl('image/jpeg') // You can use 'image/png' too
            .split(',')[1]; // Strip data URL prefix
        final imageBytes = base64Decode(encodedImageData);

        _imageStreamController.add(imageBytes);
      });

      return SuccessState.nil;
    });
  }

  @override
  Stream<Uint8List> get imageStream => _imageStreamController.stream;

  @override
  FutureNull stopImageStream() {
    return ErrorHandler.handleException(() async {
      if (_videoElement == null) {
        return FailureState(message: 'Stream is not started yet.');
      }

      _frameTimer?.cancel();
      _frameTimer = null;
      _canvasElement = null;
      _canvasContext = null;
      return SuccessState.nil;
    });
  }

  @override
  FutureNull startAudioStream() {
    return ErrorHandler.handleException(() async {
      if (_cameraStream == null) {
        return FailureState(message: 'Camera stream is not initialized.');
      }

      // Initialize audio context and create a source from the audio tracks of the MediaStream
      _audioContext = web.AudioContext();
      final source = _audioContext!.createMediaStreamSource(_cameraStream!);

      // Create a script processor node for capturing audio data
      // Buffer size: 4096 samples, 1 input channel, 1 output channel
      // The buffer size must be a power of two, from 256 to 16384, including 256, 512, 1024, 2048, 4096, 8192, 16384.
      _scriptProcessor = _audioContext!.createScriptProcessor(4096, 1, 1);

      // Set up the audio processing callback
      void audioProcessCallback(web.Event event) {
        final audioEvent = event as web.AudioProcessingEvent;

        final inputBuffer = audioEvent.inputBuffer;
        final channelData = inputBuffer
            .getChannelData(0)
            .toDart; // Mono channel

        // Convert to 16-bit signed PCM
        final byteBuffer = ByteData(channelData.length * 2);
        for (int i = 0; i < channelData.length; i++) {
          // Clamp and convert to 16-bit PCM: range [-32768, 32767]
          final sample = (channelData[i] * 32767.0)
              .clamp(-32768.0, 32767.0)
              .toInt();
          byteBuffer.setInt16(i * 2, sample, Endian.little);
        }
        final bytes = byteBuffer.buffer.asUint8List();

        _audioStreamController.add(bytes);
      }

      _scriptProcessor!.addEventListener(
        'audioprocess',
        audioProcessCallback.toJS,
      );

      // Connect audio pipeline
      source.connect(_scriptProcessor!);
      _scriptProcessor!.connect(_audioContext!.destination);

      return SuccessState.nil;
    });
  }

  @override
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  @override
  FutureNull stopAudioStream() {
    return ErrorHandler.handleException(() async {
      _scriptProcessor?.disconnect();
      _scriptProcessor = null;

      _audioContext?.close();
      _audioContext = null;

      return SuccessState.nil;
    });
  }

  // Stores the video data in the memory as a list of blobs.
  // Recording for long durations may lead to high memory usage.
  // Unfortunately, there's no direct way to stream video data to disk from a web browser due to security restrictions.
  // Solution: Downloads video chunks when memory usage exceeds like 100MB or 1GB.
  @override
  FutureNull startVideoRecording(WebVideoRecordRequest request) {
    return ErrorHandler.handleException(() async {
      if (_cameraStream == null) {
        return FailureState(message: 'Camera stream is not initialized.');
      }

      // Clear any previously recorded blobs
      _recordedBlobs = [];

      // Create a media recorder with some options.
      final options = web.MediaRecorderOptions(
        mimeType: _videoRecordType.mimeType,
        audioBitsPerSecond: request.audioBitsPerSecond,
        videoBitsPerSecond: request.videoBitsPerSecond,
      );
      _mediaRecorder = web.MediaRecorder(_cameraStream!, options);

      // Add an event listener to handle video data availability whenever the media recorder captures a chunk of video data.
      void callback(web.Event event) {
        final blobEvent = event as web.BlobEvent;
        if (blobEvent.data.size > 0) {
          _recordedBlobs.add(blobEvent.data);
        }
      }

      _mediaRecorder!.addEventListener('dataavailable', callback.toJS);
      _mediaRecorder!.start();

      return SuccessState.nil;
    });
  }

  @override
  FutureNull stopVideoRecording() {
    return ErrorHandler.handleException(() async {
      if (_mediaRecorder == null || _mediaRecorder?.state != 'recording') {
        return FailureState(message: 'MediaRecorder is not recording.');
      }

      // A completer to wait for the 'stop' event is called on the media recorder.
      final completer = Completer<DataState<Null>>();
      void callback(web.Event event) {
        completer.complete(SuccessState.nil);
      }

      _mediaRecorder?.addEventListener('stop', callback.toJS);
      _mediaRecorder?.stop();
      _mediaRecorder = null;

      return await completer.future;
    });
  }

  @override
  FutureNull saveBlobToDownloads() {
    return ErrorHandler.handleException(() async {
      final recordedBlob = web.Blob(
        _recordedBlobs.toJS as JSArray<web.BlobPart>,
      );
      final url = web.URL.createObjectURL(recordedBlob);

      // Create anchor element via JS interop
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_video.${_videoRecordType.fileType}';
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();

      // Revoke URL to free memory
      web.URL.revokeObjectURL(url);

      return SuccessState.nil;
    });
  }

  @override
  FutureNull closeCamera() {
    return ErrorHandler.handleException(() async {
      if (_canvasElement != null) await stopImageStream();
      if (_audioContext != null) await stopAudioStream();
      if (_mediaRecorder != null) await stopVideoRecording();

      // A MediaStream can contain multiple tracks like video, audio
      final mediaTracks = _cameraStream?.getTracks().toDart ?? [];
      for (final track in mediaTracks) {
        track.stop();
      }
      _cameraStream = null;
      _videoElement?.remove();
      _videoElement = null;

      return SuccessState.nil;
    });
  }
}
