import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../riverpod/provider/camera_notifier_provider.dart';

class IOSCameraActionWidget extends ConsumerWidget {
  const IOSCameraActionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(iosCameraNotifierProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: notifier.startImageStream,
              child: Text('Stream image'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: notifier.stopImageStream,
              child: Text('Stop streaming'),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: notifier.startAudioStream,
              child: Text('Stream audio'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: notifier.stopAudioStream,
              child: Text('Stop streaming'),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: notifier.startVideoRecording,
              child: Text('Record video'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: notifier.stopVideoRecording,
              child: Text('Stop recording'),
            ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(
                onPressed: notifier.switchCamera,
                child: Text('Switch Camera'),
              ),
              SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }
}
