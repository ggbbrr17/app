import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    window = UIWindow(windowScene: windowScene)
    // Usamos el controlador de Flutter por defecto que ya tiene los plugins registrados
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let flutterViewController = FlutterViewController(project: nil, initialRoute: nil, nibName: nil, bundle: nil)
    
    // Forzar transparencia a nivel de UIWindow
    flutterViewController.isViewOpaque = false
    flutterViewController.view.backgroundColor = .clear
    
    window?.rootViewController = flutterViewController
    window?.backgroundColor = UIColor(white: 0.03, alpha: 1.0) // Fondo muy oscuro pero no transparente al sistema
    window?.makeKeyAndVisible()
  }
}