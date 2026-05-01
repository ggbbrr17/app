import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Registro para notificaciones locales en primer plano
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    controller.isViewOpaque = false
    controller.view.backgroundColor = .clear
    window?.backgroundColor = UIColor.clear

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
