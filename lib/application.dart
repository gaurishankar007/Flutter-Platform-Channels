import 'package:flutter/material.dart';

import 'config/theme/theme.dart';
import 'views/camera/camera_view.dart';
import 'views/home_view.dart';

class PlatformChannelApp extends StatelessWidget {
  const PlatformChannelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Camera Test",
      theme: lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeView(),
        '/camera': (context) => const CameraView(),
      },
    );
  }
}
