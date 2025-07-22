import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/base_notifier/base_state_notifier.dart';
import '../../../../riverpod/notifier/android_camera/android_camera_notifier.dart';
import '../../../../riverpod/provider/camera_notifier_provider.dart';

class AndroidCameraWidget extends ConsumerStatefulWidget {
  const AndroidCameraWidget({super.key});

  @override
  ConsumerState<AndroidCameraWidget> createState() =>
      _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<AndroidCameraWidget>
    with WidgetsBindingObserver {
  late final AndroidCameraNotifier _cameraNotifier;
  Orientation? orientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraNotifier = ref.read(androidCameraNotifierProvider.notifier);
    _cameraNotifier.openCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaOrientation = MediaQuery.of(context).orientation;
    if (mediaOrientation != orientation) {
      if (orientation != null) _cameraNotifier.updateOrientation();
      orientation = mediaOrientation;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraNotifier.closeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _cameraNotifier.manageLifeCycle(state);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(androidCameraNotifierProvider);

    if (state.stateStatus == StateStatus.loading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.permissionDenied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const Text('Camera permissions are not granted.'),
            ElevatedButton(
              onPressed: _cameraNotifier.openCamera,
              child: Text("Request Permissions"),
            ),
          ],
        ),
      );
    }

    return RotatedBox(
      quarterTurns: state.quarterTurns,
      child: AspectRatio(
        aspectRatio: state.previewHeight / state.previewWidth,
        child: Texture(textureId: state.textureId),
      ),
    );
  }
}
