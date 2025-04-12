import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/generated/pigeon_api.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/platform_channel/PigeonApi.kt',
    kotlinOptions: KotlinOptions(),
    swiftOut: 'ios/Runner/PigeonApi.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: "com.example.platform_channel", // Package name needed
  ),
)
// Define message classes for data exchange
class GreetingRequest {
  String? name;
}

class GreetingResponse {
  String? message;
}

// Define method channel API
@HostApi()
abstract class NativeMethodsApi {
  @async
  GreetingResponse greeting(GreetingRequest request);

  @async
  int getBatteryLevel();
}

// Define event channel API using a callback interface
@FlutterApi()
abstract class FlutterEventsApi {
  void onTimeUpdate(String time);
}
