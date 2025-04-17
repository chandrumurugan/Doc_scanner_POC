import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _controller;
  ObjectDetector? _objectDetector;
  List<Offset> _corners = [];
  String? _processedImagePath;
  Size _imageSize = Size.zero;
  Size _previewSize = Size.zero;
  bool _isDetecting = false;
  bool _isProcessingImage = false;
  bool _isInitializing = false;
  String? _error;

  CameraController? get controller => _controller;
  List<Offset> get corners => _corners;
  String? get processedImagePath => _processedImagePath;
  bool get isProcessingImage => _isProcessingImage;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  Size get previewSize => _previewSize;

  Future<void> initialize() async {
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _initializeDetector();
      await _initializeCamera();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _initializeDetector() async {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: false,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    _previewSize = Size(
      _controller!.value.previewSize!.height,
      _controller!.value.previewSize!.width,
    );

    _controller!.startImageStream(_processCameraImage);
    notifyListeners();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isProcessingImage) return;
    _isDetecting = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final objects = await _objectDetector!.processImage(inputImage);
      if (objects.isEmpty) {
        _corners = [];
        notifyListeners();
        return;
      }

      final document = objects.reduce((a, b) =>
          a.boundingBox.width * a.boundingBox.height >
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b);

      final box = document.boundingBox;
      _corners = [
        Offset(box.left, box.top),
        Offset(box.right, box.top),
        Offset(box.right, box.bottom),
        Offset(box.left, box.bottom),
      ];
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> captureImage() async {
    if (_isProcessingImage || _controller == null) return;
    _isProcessingImage = true;
    notifyListeners();

    try {
      final imageFile = await _controller!.takePicture();
      await _processAndSaveImage(imageFile.path);
    } catch (e) {
      _error = 'Failed to capture image: $e';
    } finally {
      _isProcessingImage = false;
      notifyListeners();
    }
  }

  // Future<void> _processAndSaveImage(String imagePath) async {
  //   try {
  //     final originalImage = img.decodeImage(await File(imagePath).readAsBytes());
  //     if (originalImage == null) throw Exception('Failed to decode image');

  //     if (_corners.length < 4) {
  //       throw Exception('No corners detected for cropping');
  //     }

  //     final imageCorners = _convertPreviewToImageCoordinates(_corners);
  //     final processedImage = _applyPerspectiveCorrection(
  //       originalImage,
  //       imageCorners,
  //     );

  //     final directory = await getApplicationDocumentsDirectory();
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     _processedImagePath = '${directory.path}/processed_$timestamp.jpg';
  //     await File(_processedImagePath!)
  //         .writeAsBytes(img.encodeJpg(processedImage));
  //   } catch (e) {
  //     _error = 'Failed to process image: $e';
  //   }
  // }

Future<void> _processAndSaveImage(String imagePath) async {
  try {
    final originalImage = img.decodeImage(await File(imagePath).readAsBytes());
    if (originalImage == null) throw Exception('Failed to decode image');

    if (_corners.length < 4) {
      throw Exception('No corners detected for cropping');
    }

    // Convert preview coordinates to image coordinates
    final imageCorners = _convertPreviewToImageCoordinates(_corners);
    
    // Apply perspective correction
    final processedImage = _applyPerspectiveCorrection(
      originalImage,
      imageCorners,
    );

    // Save the processed image
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _processedImagePath = '${directory.path}/processed_$timestamp.jpg';
    await File(_processedImagePath!)
        .writeAsBytes(img.encodeJpg(processedImage));
  } catch (e) {
    _error = 'Failed to process image: $e';
  }
}

List<img.Point> _convertPreviewToImageCoordinates(List<Offset> corners) {
  if (_previewSize.isEmpty || _imageSize.isEmpty) return [];
  
  // Calculate how the image is scaled and positioned in the preview
  final scaleX = _previewSize.width / _imageSize.width;
  final scaleY = _previewSize.height / _imageSize.height;
  final scale = min(scaleX, scaleY);
  
  final offsetX = (_previewSize.width - _imageSize.width * scale) / 2;
  final offsetY = (_previewSize.height - _imageSize.height * scale) / 2;
  
  return corners.map((corner) {
    // Convert from preview coordinates to image coordinates
    return img.Point(
      ((corner.dx - offsetX) / scale).toInt(),
      ((corner.dy - offsetY) / scale).toInt(),
    );
  }).toList();
}

img.Image _applyPerspectiveCorrection(
  img.Image original,
  List<img.Point> corners,
) {
  // Sort corners in consistent order: top-left, top-right, bottom-right, bottom-left
  corners.sort((a, b) => a.x.compareTo(b.x));
  
  if (corners[0].y > corners[1].y) {
    final temp = corners[0];
    corners[0] = corners[1];
    corners[1] = temp;
  }
  
  if (corners[2].y < corners[3].y) {
    final temp = corners[2];
    corners[2] = corners[3];
    corners[3] = temp;
  }

  // Calculate target dimensions
  final width = ((_distanceBetweenPoints(corners[0], corners[1]) + 
                 _distanceBetweenPoints(corners[3], corners[2])) / 2).toInt();
  final height = ((_distanceBetweenPoints(corners[0], corners[3]) + 
                  _distanceBetweenPoints(corners[1], corners[2])) / 2).toInt();

  final correctedImage = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final u = x / width;
      final v = y / height;

      // Bilinear interpolation to get source coordinates
      final srcX = (corners[0].x * (1-u)*(1-v) +
                   corners[1].x * u*(1-v) +
                   corners[2].x * u*v +
                   corners[3].x * (1-u)*v).toInt();
      
      final srcY = (corners[0].y * (1-u)*(1-v) +
                   corners[1].y * u*(1-v) +
                   corners[2].y * u*v +
                   corners[3].y * (1-u)*v).toInt();

      if (srcX >= 0 && srcX < original.width && 
          srcY >= 0 && srcY < original.height) {
        correctedImage.setPixel(x, y, original.getPixel(srcX, srcY));
      }
    }
  }

  return correctedImage;
}

double _distanceBetweenPoints(img.Point a, img.Point b) {
  return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
}

  Uint8List _convertCameraImageToNV21(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _yuv420toNV21(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _bgra8888toNV21(image);
    }
    throw Exception('Unsupported image format');
  }

  Uint8List _yuv420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final buffer = Uint8List(width * height * 3 ~/ 2);
    
    // Fill Y plane
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        buffer[y * width + x] = image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
      }
    }
    
    // Fill U and V (interleaved)
    int uvIndex = width * height;
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        buffer[uvIndex++] = image.planes[1].bytes[y * uvRowStride + x * uvPixelStride];
        buffer[uvIndex++] = image.planes[2].bytes[y * uvRowStride + x * uvPixelStride];
      }
    }
    
    return buffer;
  }

  Uint8List _bgra8888toNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final buffer = Uint8List(width * height * 3 ~/ 2);
    
    for (int i = 0; i < width * height; i++) {
      final b = image.planes[0].bytes[i * 4];
      final g = image.planes[0].bytes[i * 4 + 1];
      final r = image.planes[0].bytes[i * 4 + 2];
      
      buffer[i] = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
    }
    
    int uvIndex = width * height;
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        buffer[uvIndex++] = 128;
        buffer[uvIndex++] = 128;
      }
    }
    
    return buffer;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
              _controller!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final nv21Image = _convertCameraImageToNV21(image);
      
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: nv21Image,
        metadata: metadata,
      );
    } catch (e) {
      return null;
    }
  }


void resetScanner() {
  _processedImagePath = null;
  notifyListeners();
}

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector?.close();
    super.dispose();
  }
}