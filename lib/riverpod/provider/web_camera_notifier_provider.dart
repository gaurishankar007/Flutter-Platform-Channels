import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/web_camera_service.dart';
import '../notifier/web_camera/web_camera_notifier.dart';

final webCameraNotifierProvider = StateNotifierProvider(
  (_) => WebCameraNotifier(cameraService: WebCameraServiceImpl()),
);
