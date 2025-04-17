import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class EdgePainter extends CustomPainter {
  final List<Offset> corners;
  final Size imageSize;
  final Size previewSize;
  final InputImageRotation rotation;

  EdgePainter(this.corners, this.imageSize, this.previewSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Calculate scale and offset to maintain aspect ratio
    final scale = _calculateScale();
    final offset = _calculateOffset(scale);

    // Transform detected corners to preview coordinates
    final transformedCorners = _transformCorners(scale, offset);

    // Draw document outline
    final path = Path()
      ..moveTo(transformedCorners[0].dx, transformedCorners[0].dy)
      ..lineTo(transformedCorners[1].dx, transformedCorners[1].dy)
      ..lineTo(transformedCorners[2].dx, transformedCorners[2].dy)
      ..lineTo(transformedCorners[3].dx, transformedCorners[3].dy)
      ..close();
    
    canvas.drawPath(path, paint);

    // Draw corner markers
    for (final corner in transformedCorners) {
      canvas.drawCircle(corner, 12, paint..style = PaintingStyle.fill);
    }
  }

  double _calculateScale() {
    final imageAspect = imageSize.width / imageSize.height;
    final previewAspect = previewSize.width / previewSize.height;
    
    // Account for rotation
    if (rotation == InputImageRotation.rotation90deg || 
        rotation == InputImageRotation.rotation270deg) {
      return previewAspect > 1/imageAspect
          ? previewSize.height / imageSize.width
          : previewSize.width / imageSize.height;
    } else {
      return previewAspect > imageAspect
          ? previewSize.height / imageSize.height
          : previewSize.width / imageSize.width;
    }
  }

  Offset _calculateOffset(double scale) {
    if (rotation == InputImageRotation.rotation90deg || 
        rotation == InputImageRotation.rotation270deg) {
      return Offset(
        (previewSize.width - imageSize.height * scale) / 2,
        (previewSize.height - imageSize.width * scale) / 2,
      );
    } else {
      return Offset(
        (previewSize.width - imageSize.width * scale) / 2,
        (previewSize.height - imageSize.height * scale) / 2,
      );
    }
  }

  List<Offset> _transformCorners(double scale, Offset offset) {
    return corners.map((corner) {
      double x, y;
      
      // Convert from image coordinates to preview coordinates
      switch (rotation) {
        case InputImageRotation.rotation90deg:
          x = corner.dy;
          y = imageSize.width - corner.dx;
          break;
        case InputImageRotation.rotation180deg:
          x = imageSize.width - corner.dx;
          y = imageSize.height - corner.dy;
          break;
        case InputImageRotation.rotation270deg:
          x = imageSize.height - corner.dy;
          y = corner.dx;
          break;
        default:
          x = corner.dx;
          y = corner.dy;
      }
      
      return Offset(
        offset.dx + x * scale,
        offset.dy + y * scale,
      );
    }).toList();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}