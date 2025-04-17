import 'dart:io';
import 'package:doc_sacnner_poc/Utils/customEdge_painter.dart';
import 'package:doc_sacnner_poc/provider/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doc scanner poc')),
      body: Consumer<CameraProvider>(
        builder: (context, provider, child) {
          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.isInitializing || provider.controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.processedImagePath != null) {
            return _ImagePreview(
              imagePath: provider.processedImagePath!,
              onReturn: () => provider.resetScanner(),
            );
          }

          return _CameraPreview(
            controller: provider.controller!,
            previewSize: provider.previewSize,
            corners: provider.corners,
          );
        },
      ),
      floatingActionButton: Consumer<CameraProvider>(
        builder: (context, provider, child) {
          if (provider.controller == null &&
              provider.processedImagePath == null) {
            return const SizedBox();
          }

          return FloatingActionButton(
            onPressed: () {
              if (provider?.processedImagePath == null) {
                provider.captureImage();
              } else {
                _showImageDialog(context, provider.processedImagePath!);
              }
            },
            child: const Icon(Icons.camera),
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Image Processed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(imagePath)),
                const SizedBox(height: 10),
                Text('Image saved to: ${imagePath.split('/').last}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () => _shareImage(context),
                child: const Text('Share'),
              ),
            ],
          ),
    );
  }

  void _shareImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;
  final Size previewSize;
  final List<Offset> corners;

  const _CameraPreview({
    required this.controller,
    required this.previewSize,
    required this.corners,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            CameraPreview(controller),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: EdgePainter(
                corners,
                // Make sure this is original image size from detection input
                Size(
                  controller.value.previewSize!.height,
                  controller.value.previewSize!.width,
                ),
                Size(constraints.maxWidth, constraints.maxHeight),
                InputImageRotationValue.fromRawValue(
                      controller.description.sensorOrientation,
                    ) ??
                    InputImageRotation.rotation0deg,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onReturn;

  const _ImagePreview({required this.imagePath, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(child: Image.file(File(imagePath),fit: BoxFit.cover,)),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.teal,
            onPressed: onReturn,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}
