import 'package:flutter/material.dart';

import 'views/home_view.dart';

void main() {
  runApp(const PlatformChannelExample());
}

class PlatformChannelExample extends StatelessWidget {
  const PlatformChannelExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Platform Channels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
