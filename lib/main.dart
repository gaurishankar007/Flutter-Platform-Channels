import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_initializer.dart';
import 'application.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initializeApp();

  runApp(ProviderScope(child: PlatformChannelApp()));
}
