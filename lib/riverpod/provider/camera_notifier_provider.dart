import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/android_camera_service.dart';
import '../../core/services/ios_camera_service.dart';
import '../notifier/android_camera/android_camera_notifier.dart';
import '../notifier/ios_camera/ios_camera_notifier.dart';

final androidCameraNotifierProvider = StateNotifierProvider(
  (_) => AndroidCameraNotifier(
    cameraService: GetIt.instance<AndroidCameraService>(),
  ),
);

final iosCameraNotifierProvider = StateNotifierProvider(
  (_) => IOSCameraNotifier(cameraService: GetIt.instance<IOSCameraService>()),
);
