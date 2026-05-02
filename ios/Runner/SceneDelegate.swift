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
    window?.backgroundColor = .black
    window?.makeKeyAndVisible()

    // Registramos los plugins con el motor de Flutter
    GeneratedPluginRegistrant.register(with: controller.engine)
  }
}