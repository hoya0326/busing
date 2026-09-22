import Flutter
import UIKit
import WidgetKit // 💡 WidgetCenter를 위해 추가
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private var widgetClickPending: Bool = false

    func setWidgetClickPending(_ value: Bool) {
        widgetClickPending = value
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let widgetChannel = FlutterMethodChannel(name: "com.example.busing/widget",
                                                  binaryMessenger: controller.binaryMessenger)

        widgetChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }

            if call.method == "updateWidget" {
                if let args = call.arguments as? [String: Any] {
                    // App Group UserDefaults에 저장 (설정되지 않았을 경우 standard에 임시 저장)
                    let prefs = UserDefaults(suiteName: "group.com.example.busing") ?? UserDefaults.standard
                    if let busName = args["busName"] as? String {
                        prefs.set(busName, forKey: "flutter.widget_busName")
                    }
                    if let remainMin = args["remainMin"] as? String {
                        prefs.set(remainMin, forKey: "flutter.widget_remainMin")
                    }
                    if let stopName = args["stopName"] as? String {
                        prefs.set(stopName, forKey: "flutter.widget_stopName")
                    }
                    if let destinationName = args["destinationName"] as? String, !destinationName.isEmpty {
                        prefs.set(destinationName, forKey: "flutter.widget_destination")
                    }
                }

                // 💡 WidgetKit 타임라인 즉시 갱신
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                result(true)

            } else if call.method == "checkWidgetClick" {
                // 위젯이 클릭된 적이 있는지 확인하고 플래그 리셋
                let clicked = self.widgetClickPending
                self.widgetClickPending = false
                result(clicked)

            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // 💡 위젯 클릭 시 전달되는 URL 처리
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "busing" && url.host == "widget_click" {
            widgetClickPending = true
            return true
        }
        return super.application(app, open: url, options: options)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
