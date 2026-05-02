import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    window = UIWindow(windowScene: windowScene)
    
    // Creamos el controlador principal de Flutter
    let controller = FlutterViewController(project: nil, initialRoute: nil, nibName: nil, bundle: nil)

    // Aplicamos la configuración de transparencia (Glassmorphism)
    controller.isViewOpaque = false
    controller.view.backgroundColor = .clear
    window?.rootViewController = controller
    window?.backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1.0)
    window?.makeKeyAndVisible()

    // Registramos los plugins con el motor de Flutter
    GeneratedPluginRegistrant.register(with: controller.engine)
  }
}