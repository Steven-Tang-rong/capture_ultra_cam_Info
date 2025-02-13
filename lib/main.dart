import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'ios_camera_helper.dart';

void main() async {
  // 確保 Flutter 綁定初始化
  WidgetsFlutterBinding.ensureInitialized();

  final iPhoneCameras = await IOSCameraHelper.getCameraList();
  print("\n=== iOS 原生相機清單 ===");
  for (var camera in iPhoneCameras) {
    print('名稱: ${camera["name"]}');
    print('類型: ${camera["type"]}');
    print('位置: ${camera["position"]}');
    print('ID: ${camera["uniqueID"]}');
    print('------------------');
  }

  // 取得所有可用的相機
  final cameras = await availableCameras();

  // 印出所有相機資訊
  // print('\n=== 可用相機清單 ===');
  // for (var i = 0; i < cameras.length; i++) {
  //   print('\n相機 #$i:');
  //   print('名稱: ${cameras[i].name}');
  //   print('鏡頭方向: ${cameras[i].lensDirection.toString()}');
  //   print('感測器方向: ${cameras[i].sensorOrientation}度');
  // }
  // print('\n==================\n');

  await checkCameraZoomLevels(cameras);

  runApp(
    MaterialApp(
      home: CameraApp(cameras: cameras),
    ),
  );
}

// **檢查相機的最小縮放等級**
Future<void> checkCameraZoomLevels(List<CameraDescription> cameras) async {
  for (var camera in cameras) {
    final controller = CameraController(camera, ResolutionPreset.medium);

    try {
      await controller.initialize();

      double minZoom = await controller.getMinZoomLevel();
      double maxZoom = await controller.getMaxZoomLevel();

      // print('相機: ${camera.name}');
      // print('最小可用縮放: $minZoom');
      // print('最大可用縮放: $maxZoom');
      // print('------------------');

      await controller.dispose();

      // **判斷哪顆是超廣角鏡頭**
      if (minZoom == 0.5) {
        print('✅ 找到超廣角鏡頭: ${camera.name}');
      }
    } catch (e) {
      print('⚠️ 讀取相機縮放資訊時發生錯誤: $e');
    }
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraApp({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  bool _isInitialized = false;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  // 目前選擇的相機索引
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
  }

  // 初始化相機
  Future<void> _initializeCamera(int cameraIndex) async {
    final CameraController cameraController = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController.initialize();

      // 取得相機支援的縮放範圍
      _baseZoom = await cameraController.getMinZoomLevel();

      setState(() {
        _controller = cameraController;
        _isInitialized = true;
        _currentZoom = _baseZoom;
      });
    } catch (e) {
      print('相機初始化錯誤: $e');
    }
  }

  // 切換相機鏡頭
  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _isInitialized = false;
    });
    _initializeCamera(_selectedCameraIndex);
  }

  // 調整縮放
  Future<void> _setZoomLevel(double zoom) async {
    if (!_controller.value.isInitialized) return;

    try {
      await _controller.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      print('設定縮放等級錯誤: $e');
    }
  }

  // 拍照
  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) return;

    try {
      // 取得暫存目錄路徑
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      // 產生檔案名稱
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempPath, fileName);

      // 拍照並儲存
      final XFile photo = await _controller.takePicture();
      await photo.saveTo(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('照片已儲存至: $filePath')),
      );
    } catch (e) {
      print('拍照錯誤: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('相機範例')),
      body: Stack(
        children: [
          // 相機預覽
          Center(
            child: CameraPreview(_controller),
          ),

          // 縮放滑桿
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Slider(
              value: _currentZoom,
              min: _baseZoom,
              max: 5.0,
              onChanged: _setZoomLevel,
            ),
          ),

          // 控制按鈕
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 切換鏡頭按鈕
                IconButton(
                  icon: const Icon(Icons.switch_camera),
                  color: Colors.white,
                  onPressed: _switchCamera,
                ),
                // 拍照按鈕
                IconButton(
                  icon: const Icon(Icons.camera),
                  color: Colors.white,
                  iconSize: 50,
                  onPressed: _takePicture,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}