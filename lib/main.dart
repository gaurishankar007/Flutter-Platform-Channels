import 'package:flutter/material.dart';

import 'views/android_channel_view.dart';
import 'views/home_view.dart';
import 'views/ios_channel_view.dart';

void main() {
  runApp(const FlutterChannel());
}

class FlutterChannel extends StatelessWidget {
  const FlutterChannel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Platform Channels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const HomeView(),
        '/ios': (context) => const IOSChannelView(),
        '/android': (context) => const AndroidChannelView(),
      },
    );
  }
}
