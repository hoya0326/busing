import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        super.scene(scene, openURLContexts: URLContexts)

        for context in URLContexts {
            let url = context.url
            if url.scheme == "busing" && url.host == "widget_click" {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.setWidgetClickPending(true)
                }
            }
        }
    }
}
