import 'package:flutter/services.dart';

class IOSCameraHelper {
  static const MethodChannel _channel = MethodChannel('camera_channel');

  static Future<List<Map<String, dynamic>>> getCameraList() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getCameraList');
      return result
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print("❌ ST - 無法獲取相機列表: $e");
      return [];
    }
  }
}