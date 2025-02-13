//
//  CameraHelper.swift
//  Runner
//
//  Created by Steven on 2025/2/12.
//

import AVFoundation

@objc class CameraHelper: NSObject {
    @objc static func getCameraList() -> [[String: Any]] {
        var cameras: [[String: Any]] = []

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: .unspecified
        )

        for device in discoverySession.devices {
            var type = "Unknown"
            
            print("ST - device.deviceType: \(device.deviceType)")

            switch device.deviceType {
            case .builtInWideAngleCamera:
                type = "WideAngle"
            case .builtInUltraWideCamera:
                type = "UltraWide"
            case .builtInTelephotoCamera:
                type = "Telephoto"
            case .builtInTrueDepthCamera:
                type = "FrontCamera"
            case .builtInDualCamera:
                type = "DualCamera"
            case .builtInTripleCamera:
                type = "TripleCamera"
                
            default:
                break
            }

            cameras.append([
                "name": device.localizedName,
                "type": type,
                "position": device.position == .front ? "Front" : "Back",
                "uniqueID": device.uniqueID
            ])
        }

        return cameras
    }
}
