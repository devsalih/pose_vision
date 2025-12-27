import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose? pose;
  final List<String> currentFaults;
  final ui.Size imageSize;
  final ui.Size screenSize;

  PosePainter({
    required this.pose,
    required this.currentFaults,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final imageWidth = imageSize.width;
    final imageHeight = imageSize.height;

    // Matches BoxFit.cover so landmarks stay aligned with the camera preview.
    final scaleX = screenSize.width / imageWidth;
    final scaleY = screenSize.height / imageHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    final scaledWidth = imageWidth * scale;
    final scaledHeight = imageHeight * scale;

    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;

    const leftColor = Color(0xFFFF1493); // Magenta/Pink
    const rightColor = Color(0xFF00CED1); // Cyan

    final landmarks = pose!.landmarks;

    _drawConnections(
      canvas,
      landmarks,
      scale,
      offsetX,
      offsetY,
      leftColor,
      rightColor,
    );

    _drawLandmarks(
      canvas,
      landmarks,
      scale,
      offsetX,
      offsetY,
      leftColor,
      rightColor,
    );
  }

  void _drawConnections(
    Canvas canvas,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    double scale,
    double offsetX,
    double offsetY,
    Color leftColor,
    Color rightColor,
  ) {
    final leftConnections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    ];

    final rightConnections = [
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    final centerConnections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    ];

    final leftPaint = Paint()
      ..color = leftColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final rightPaint = Paint()
      ..color = rightColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    for (final connection in leftConnections) {
      final p1 = landmarks[connection[0]];
      final p2 = landmarks[connection[1]];
      if (p1 == null || p2 == null) continue;

      canvas.drawLine(
        Offset(p1.x * scale + offsetX, p1.y * scale + offsetY),
        Offset(p2.x * scale + offsetX, p2.y * scale + offsetY),
        leftPaint,
      );
    }

    for (final connection in rightConnections) {
      final p1 = landmarks[connection[0]];
      final p2 = landmarks[connection[1]];
      if (p1 == null || p2 == null) continue;

      canvas.drawLine(
        Offset(p1.x * scale + offsetX, p1.y * scale + offsetY),
        Offset(p2.x * scale + offsetX, p2.y * scale + offsetY),
        rightPaint,
      );
    }

    for (final connection in centerConnections) {
      final p1 = landmarks[connection[0]];
      final p2 = landmarks[connection[1]];
      if (p1 == null || p2 == null) continue;

      final offset1 = Offset(p1.x * scale + offsetX, p1.y * scale + offsetY);
      final offset2 = Offset(p2.x * scale + offsetX, p2.y * scale + offsetY);

      final gradientPaint = Paint()
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..shader = ui.Gradient.linear(
          offset1,
          offset2,
          [leftColor, rightColor],
        );

      canvas.drawLine(offset1, offset2, gradientPaint);
    }
  }

  void _drawLandmarks(
    Canvas canvas,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    double scale,
    double offsetX,
    double offsetY,
    Color leftColor,
    Color rightColor,
  ) {
    final leftLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    ];

    final rightLandmarks = [
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    ];

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final leftFillPaint = Paint()
      ..color = leftColor
      ..style = PaintingStyle.fill;

    final rightFillPaint = Paint()
      ..color = rightColor
      ..style = PaintingStyle.fill;

    for (final landmarkType in leftLandmarks) {
      final landmark = landmarks[landmarkType];
      if (landmark == null) continue;

      final offset = Offset(
        landmark.x * scale + offsetX,
        landmark.y * scale + offsetY,
      );

      canvas.drawCircle(offset, 8.0, leftFillPaint);
      canvas.drawCircle(offset, 8.0, strokePaint);
    }

    for (final landmarkType in rightLandmarks) {
      final landmark = landmarks[landmarkType];
      if (landmark == null) continue;

      final offset = Offset(
        landmark.x * scale + offsetX,
        landmark.y * scale + offsetY,
      );

      canvas.drawCircle(offset, 8.0, rightFillPaint);
      canvas.drawCircle(offset, 8.0, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.currentFaults != currentFaults;
  }
}
