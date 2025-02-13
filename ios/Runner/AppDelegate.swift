import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController =
            window?.rootViewController as! FlutterViewController
        
        let cameraChannel = FlutterMethodChannel(
            name: "camera_channel", binaryMessenger: controller.binaryMessenger)
        
        cameraChannel.setMethodCallHandler({ (call, result) in
            if call.method == "getCameraList" {
                let cameras = CameraHelper.getCameraList()
                result(cameras)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(
            application, didFinishLaunchingWithOptions: launchOptions)
    }
}
