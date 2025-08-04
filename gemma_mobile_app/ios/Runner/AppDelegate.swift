import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register MediaPipe text embedder plugin
    if let controller = window?.rootViewController as? FlutterViewController {
      MediaPipeTextEmbedderPlugin.register(with: registrar(forPlugin: "MediaPipeTextEmbedderPlugin")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
