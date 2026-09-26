import Flutter
import UIKit
import WidgetKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

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
            if let count = args["count"] as? Int {
              defaults?.set(count, forKey: "widget_count")
            }
            if let items = args["items"] as? [[String: Any]] {
              for (index, item) in items.enumerated() {
                if let busName = item["busName"] as? String {
                  defaults?.set(busName, forKey: "widget_busName_\(index)")
                }
                if let remainMin = item["remainMin"] as? String {
                  defaults?.set(remainMin, forKey: "widget_remainMin_\(index)")
                }
                if let stopName = item["stopName"] as? String {
                  defaults?.set(stopName, forKey: "widget_stopName_\(index)")
                }
                if let destinationName = item["destinationName"] as? String {
                  defaults?.set(destinationName, forKey: "widget_destination_\(index)")
                }
              }
              if let first = items.first {
                if let busName = first["busName"] as? String {
                  defaults?.set(busName, forKey: "widget_busName")
                }
                if let remainMin = first["remainMin"] as? String {
                  defaults?.set(remainMin, forKey: "widget_remainMin")
                }
                if let stopName = first["stopName"] as? String {
                  defaults?.set(stopName, forKey: "widget_stopName")
                }
                if let destinationName = first["destinationName"] as? String {
                  defaults?.set(destinationName, forKey: "widget_destination")
                }
              }
            } else {
              if let busName = args["busName"] as? String {
                defaults?.set(busName, forKey: "widget_busName")
              }
              if let remainMin = args["remainMin"] as? String {
                defaults?.set(remainMin, forKey: "widget_remainMin")
              }
              if let stopName = args["stopName"] as? String {
                defaults?.set(stopName, forKey: "widget_stopName")
              }
              if let destinationName = args["destinationName"] as? String {
                defaults?.set(destinationName, forKey: "widget_destination")
              }
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

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if url.scheme == "busing" {
      let defaults = UserDefaults(suiteName: "group.com.example.busing")
      defaults?.set(true, forKey: "widget_clicked")
    }
    return super.application(app, open: url, options: options)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge, .list])
  }
}
