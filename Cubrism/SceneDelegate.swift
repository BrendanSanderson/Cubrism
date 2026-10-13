import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        app.configureGame(in: window)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.resetGameControls()
    }
}
