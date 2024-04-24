import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  let channel = "flutter.native/helper"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: channel, binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler( {
      (call: FlutterMethodCall, result: FlutterResult) -> Void in

      switch call.method {
        case "greeting":        
          let arguments = call.arguments as Map<String, String>
          let name = arguments["name"]
          result("Hi \(name)! I am Swift 😎")
        case "getBatteryLevel":
          let batteryLevel = getBatteryLevel()
          if batteryLevel == -1 {
            result(
              FlutterError(
                code: "UNAVAILABLE",
                message: "Battery information not available",
                details: nil,
              )
            )
          } else {
            result(batteryLevel)
          }
        default:
          result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getBatteryLevel() -> Int {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    if device.batteryState == UIDevice.BatteryState.unknown {
      return -1
    } else {
      return Int(device.batteryLevel * 100)
    }
  }
}
