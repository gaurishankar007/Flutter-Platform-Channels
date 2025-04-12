import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, NativeMethodsApi {
    private var timer: Timer?
    private var flutterApi: FlutterEventsApi?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let binaryMessenger = controller.binaryMessenger

        // Register Flutter -> Native API
        NativeMethodsApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
        // Setup FlutterEventsApi for native -> Flutter communication
        flutterApi = FlutterEventsApi(binaryMessenger: binaryMessenger)
        // Start timer to send time updates
        startSendingTime()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func greeting(
        request: GreetingRequest, completion: @escaping (Result<GreetingResponse, Error>) -> Void
    ) {
        var response = GreetingResponse()
        if let name = request.name {
            response.message = "Hi \(name)! I am Swift 🍎"
        } else {
            response.message = "Hello from Swift"
        }
        completion(.success(response))
    }

    func getBatteryLevel(completion: @escaping (Result<Int64, Error>) -> Void) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            completion(.success(Int64(level * 100)))
        } else {
            completion(.success(Int64(-1)))
        }
    }

    func startSendingTime() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: Date())
            self.flutterApi?.onTimeUpdate(time: timeString, completion: { _ in })
        }
    }
}
