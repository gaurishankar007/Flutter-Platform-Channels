import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var timer: Timer?
    private var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: "flutter_native/methods", binaryMessenger: controller.binaryMessenger)
        let eventChannel = FlutterEventChannel(name: "flutter_native/events", binaryMessenger: controller.binaryMessenger)

        // MethodChannel for greeting and battery level
        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "greeting":
                if let args = call.arguments as? [String: String], let name = args["name"] {
                    result("Hi \(name)! I am Swift 🍎")
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Name required", details: nil))
                }
            case "getBatteryLevel":
                UIDevice.current.isBatteryMonitoringEnabled = true
                let level = UIDevice.current.batteryLevel
                if level >= 0 {
                    result(Int(level * 100))
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "Battery info unavailable", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // EventChannel for sending time updates every second
        eventChannel.setStreamHandler(self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: Date())
            events(timeString)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        timer?.invalidate()
        timer = nil
        eventSink = nil
        return nil
    }
}
