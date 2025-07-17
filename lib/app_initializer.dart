import 'injector/injector.dart';

class AppInitializer {
  const AppInitializer._();

  static Future<void> initializeApp() async {
    configureDependencies();
  }
}
