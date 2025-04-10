import 'package:flutter/services.dart';

class PlatformController {
  final _methodChannel = const MethodChannel("flutter_native/methods");
  final _eventChannel = const EventChannel("flutter_native/events");

  const PlatformController._();
  static final PlatformController _platformController = PlatformController._();

  factory PlatformController() => _platformController;

  Future<(String? value, String? error)> greeting() async {
    return _exceptionHandler(() async {
      final argument = {"name": "Flutter"};
      final String greeting = await _methodChannel.invokeMethod(
        'greeting',
        argument,
      );
      return (greeting, null);
    });
  }

  Future<(int? value, String? error)> getBatteryLevel() {
    return _exceptionHandler(() async {
      final int batteryLevel = await _methodChannel.invokeMethod(
        'getBatteryLevel',
      );
      return (batteryLevel, null);
    });
  }

  Stream<String> getEventStream() {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => event as String,
    );
  }

  Future<(T? value, String? error)> _exceptionHandler<T>(
    Future<(T? value, String? error)> Function() callback,
  ) async {
    try {
      return await callback();
    } on PlatformException catch (error) {
      return (null, error.toString());
    } catch (error) {
      return (null, error.toString());
    }
  }
}
