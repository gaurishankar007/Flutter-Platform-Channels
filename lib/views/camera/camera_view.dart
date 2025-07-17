import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'widgets/android_camera_action_widget.dart';
import 'widgets/android_camera_widget.dart';
import 'widgets/ios_camera_action_widget.dart';
import 'widgets/ios_camera_widget.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            children: [
              if (Platform.isAndroid) ...[
                SizedBox(height: 500, child: AndroidCameraWidget()),
                AndroidCameraActionWidget(),
              ] else if (Platform.isIOS) ...[
                SizedBox(height: 500, child: IOSCameraWidget()),
                IOSCameraActionWidget(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
