import 'dart:async' show StreamController;
import 'dart:developer' show log;

import '../pigeons/generated/pigeon_api.dart';

class PlatformController {
  // API client generated by Pigeon
  final _methodsApi = NativeMethodsApi();
  // Stream controller for time updates
  final _streamController = StreamController<String>.broadcast();

  PlatformController._() {
    FlutterEventsApi.setUp(
      _FlutterEventsApiImplementation(streamController: _streamController),
    );
  }

  static final PlatformController _platformController = PlatformController._();
  factory PlatformController() => _platformController;

  // Method channel APIs
  Future<String> greeting(String name) async {
    try {
      final request = GreetingRequest()..name = name;
      final response = await _methodsApi.greeting(request);
      return response.message ?? 'No greeting received';
    } catch (e) {
      log('Error while greeting');
      return "";
    }
  }

  Future<int> getBatteryLevel() async {
    try {
      return await _methodsApi.getBatteryLevel();
    } catch (e) {
      log('Error getting battery level: $e');
      return -1;
    }
  }

  // Event channel stream
  Stream<String> get timeUpdatesStream => _streamController.stream;

  void dispose() => _streamController.close();
}

// Implementation of the callback interface for the Flutter side
class _FlutterEventsApiImplementation extends FlutterEventsApi {
  final StreamController<String> streamController;
  _FlutterEventsApiImplementation({required this.streamController});

  @override
  void onTimeUpdate(String time) => streamController.add(time);
}
