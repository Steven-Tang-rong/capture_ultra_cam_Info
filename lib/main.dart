import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'ios_camera_helper.dart';

void main() async {
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

  final cameras = await availableCameras();

  runApp(
    MaterialApp(
      home: CameraApp(cameras: cameras),
    ),
  );
}

Future<void> checkCameraZoomLevels(List<CameraDescription> cameras) async {
  for (var camera in cameras) {
    final controller = CameraController(camera, ResolutionPreset.medium);

    try {
      await controller.initialize();

      double minZoom = await controller.getMinZoomLevel();
      double maxZoom = await controller.getMaxZoomLevel();

      await controller.dispose();

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

  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
  }

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

  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _isInitialized = false;
    });
    _initializeCamera(_selectedCameraIndex);
  }

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

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) return;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempPath, fileName);

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