import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/base_notifier/base_state_notifier.dart';
import '../../../../riverpod/notifier/web_camera/web_camera_notifier.dart';
import '../../../../riverpod/provider/web_camera_notifier_provider.dart';

class WebCameraWidget extends ConsumerStatefulWidget {
  const WebCameraWidget({super.key});

  @override
  ConsumerState<WebCameraWidget> createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends ConsumerState<WebCameraWidget> {
  late final WebCameraNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(webCameraNotifierProvider.notifier);
    _notifier.openCamera();
  }

  @override
  void dispose() {
    _notifier.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webCameraNotifierProvider);

    if (state.stateStatus == StateStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.permissionDenied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Camera or microphone permissions are not granted. Enable it from the browser settings.',
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _notifier.openCamera,
              child: const Text("Open camera again"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: HtmlElementView(viewType: state.htmlElementType),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _notifier.startImageStream,
              child: Text('Stream image'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _notifier.stopImageStream,
              child: Text('Stop streaming'),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _notifier.startAudioStream,
              child: Text('Stream audio'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _notifier.stopAudioStream,
              child: Text('Stop streaming'),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _notifier.startVideoRecording,
              child: Text('Record video'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _notifier.stopVideoRecording,
              child: Text('Stop recording'),
            ),
          ],
        ),
      ],
    );
  }
}
