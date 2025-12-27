import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show Size;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Converts CameraImage frames into ML Kit InputImage instances.
class ImageProcessor {
  // Used by the camera pipeline to avoid overlapping frame conversions.
  bool _isProcessing = false;

  // Builds an InputImage with correct bytes + metadata for the current platform.
  Future<InputImage?> convertCameraImage(
    CameraImage image,
    InputImageRotation rotation,
  ) async {
    try {
      final Uint8List bytes;
      final InputImageFormat? format;
      final int bytesPerRow;

      if (Platform.isAndroid) {
        // Android typically provides YUV_420_888; ML Kit expects a single byte buffer.
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();

        format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format == null) {
          debugPrint('Unsupported image format: ${image.format.raw}');
          return null;
        }

        // bytesPerRow must come from the plane metadata, not from the image width.
        bytesPerRow = image.planes[0].bytesPerRow;
      } else if (Platform.isIOS) {
        // iOS typically provides BGRA8888 in the first plane.
        bytes = image.planes.first.bytes;
        format = InputImageFormat.bgra8888;

        // bytesPerRow must come from the plane metadata, not from the image width.
        bytesPerRow = image.planes.first.bytesPerRow;
      } else {
        debugPrint('Unsupported platform');
        return null;
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e, stackTrace) {
      debugPrint('Error converting camera image: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  bool get isProcessing => _isProcessing;

  set isProcessing(bool value) {
    _isProcessing = value;
  }
}
