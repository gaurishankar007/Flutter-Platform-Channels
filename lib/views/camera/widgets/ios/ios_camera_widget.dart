import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/base_notifier/base_state_notifier.dart';
import '../../../../riverpod/notifier/ios_camera/ios_camera_notifier.dart';
import '../../../../riverpod/provider/camera_notifier_provider.dart';

class IOSCameraWidget extends ConsumerStatefulWidget {
  const IOSCameraWidget({super.key});

  @override
  ConsumerState<IOSCameraWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<IOSCameraWidget> {
  late final IOSCameraNotifier _cameraNotifier;
  Orientation? orientation;

  @override
  void initState() {
    super.initState();

    _cameraNotifier = ref.read(iosCameraNotifierProvider.notifier);
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
    _cameraNotifier.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iosCameraNotifierProvider);

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
              onPressed: _cameraNotifier.openSetting,
              child: Text("Request Permissions"),
            ),
          ],
        ),
      );
    }

    return RotatedBox(
      quarterTurns: state.quarterTurns,
      child: AspectRatio(
        aspectRatio: state.previewWidth / state.previewHeight,
        child: Texture(textureId: state.textureId),
      ),
    );
  }
}
