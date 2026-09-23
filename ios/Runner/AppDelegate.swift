import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(name: "com.example.busing/widget",
                                               binaryMessenger: controller.binaryMessenger)
      widgetChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        let defaults = UserDefaults(suiteName: "group.com.example.busing")

        if call.method == "checkWidgetClick" {
          let clicked = defaults?.bool(forKey: "widget_clicked") ?? false
          defaults?.set(false, forKey: "widget_clicked")
          result(clicked)
        } else if call.method == "updateWidget" {
          if let args = call.arguments as? [String: Any] {
            if let busName = args["busName"] as? String {
              defaults?.set(busName, forKey: "widget_busName")
            }
            if let remainMin = args["remainMin"] as? String {
              defaults?.set(remainMin, forKey: "widget_remainMin")
            }
            if let stopName = args["stopName"] as? String {
              defaults?.set(stopName, forKey: "widget_stopName")
            }
            if let destinationName = args["destinationName"] as? `String` {
              defaults?.set(destinationName, forKey: "widget_destination")
            }
          }
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
