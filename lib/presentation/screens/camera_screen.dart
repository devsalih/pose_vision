import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/core/services/permission_service.dart';
import 'package:pose_vision/core/services/toast_service.dart';
import 'package:pose_vision/core/utils/image_converter.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_bloc.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_event.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_state.dart';
import 'package:pose_vision/presentation/widgets/pose_painter.dart';

class CameraScreen extends StatefulWidget {
  final ExerciseType exerciseType;
  final int targetReps;

  const CameraScreen({
    super.key,
    required this.exerciseType,
    required this.targetReps,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = getIt<PoseDetector>();
  final ImageProcessor _imageProcessor = getIt<ImageProcessor>();
  final PermissionService _permissionService = getIt<PermissionService>();

  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isSwitching = false;
  String? _errorMessage;

  Pose? _previousPose;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<WorkoutBloc>().add(StartWorkout(
            exerciseType: widget.exerciseType,
            targetReps: widget.targetReps,
            languageCode: context.locale.languageCode,
          ));
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'error_no_camera'.tr();
        });
        return;
      }

      final List<CameraDescription> filteredCameras = [];
      final Set<CameraLensDirection> handledDirections = {};

      for (final camera in cameras) {
        if (!handledDirections.contains(camera.lensDirection)) {
          filteredCameras.add(camera);
          handledDirections.add(camera.lensDirection);
        }
      }

      _cameras = filteredCameras;

      final camera = _cameras[_currentCameraIndex];

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      _startImageStream();

      setState(() {
        _isInitialized = true;
      });
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt') {
        if (mounted) {
          _showPermissionDialog();
        }
      } else {
        setState(() {
          _errorMessage = 'error_camera_init'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'error_camera_init'.tr();
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      setState(() {
        _isSwitching = true;
        _previousPose = null;
      });

      final oldController = _cameraController;

      await oldController?.stopImageStream();
      await oldController?.dispose();

      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

      final newController = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _cameraController = newController;
        _isInitialized = true;
        _isSwitching = false;
      });

      _startImageStream();
    } catch (e) {
      setState(() {
        _errorMessage = 'error_camera_init'.tr();
      });
    }
  }

  void _startImageStream() {
    _cameraController!.startImageStream((image) async {
      if (_imageProcessor.isProcessing) return;

      _imageProcessor.isProcessing = true;
      try {
        final rotation = _getImageRotation();
        final inputImage =
            await _imageProcessor.convertCameraImage(image, rotation);

        if (inputImage != null) {
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty && mounted) {
            final smoothedPose = _smoothPose(poses.first);
            context.read<WorkoutBloc>().add(PoseDetected(smoothedPose));
          }
        }
      } catch (e) {
        debugPrint('Error processing frame: $e');
      } finally {
        _imageProcessor.isProcessing = false;
      }
    });
  }

  // Exponential smoothing reduces jitter without adding noticeable latency.
  Pose _smoothPose(Pose newPose) {
    if (_previousPose == null) {
      _previousPose = newPose;
      return newPose;
    }

    const smoothingFactor = 0.3;
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in newPose.landmarks.entries) {
      final landmarkType = entry.key;
      final newLandmark = entry.value;
      final prevLandmark = _previousPose!.landmarks[landmarkType];

      if (prevLandmark != null) {
        final smoothedX = prevLandmark.x * (1 - smoothingFactor) +
            newLandmark.x * smoothingFactor;
        final smoothedY = prevLandmark.y * (1 - smoothingFactor) +
            newLandmark.y * smoothingFactor;
        final smoothedZ = prevLandmark.z * (1 - smoothingFactor) +
            newLandmark.z * smoothingFactor;

        smoothedLandmarks[landmarkType] = PoseLandmark(
          type: landmarkType,
          x: smoothedX,
          y: smoothedY,
          z: smoothedZ,
          likelihood: newLandmark.likelihood,
        );
      } else {
        smoothedLandmarks[landmarkType] = newLandmark;
      }
    }

    final smoothedPose = Pose(
      landmarks: smoothedLandmarks,
    );

    _previousPose = smoothedPose;
    return smoothedPose;
  }

  InputImageRotation _getImageRotation() {
    if (Platform.isAndroid) {
      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      return _rotationIntToImageRotation(sensorOrientation);
    }

    // iOS preview is already delivered upright for the current configuration.
    return InputImageRotation.rotation0deg;
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('camera_permission_required'.tr()),
        content: Text('camera_permission_settings'.tr()),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _permissionService.openSettings();

              if (!mounted) return;

              final hasPermission =
                  await _permissionService.checkCameraPermission();
              if (hasPermission) {
                _initializeCamera();
              } else {
                Navigator.pop(context);
              }
            },
            child: Text('open_settings'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : !_isInitialized || _isSwitching
              ? const Center(child: CircularProgressIndicator())
              : BlocConsumer<WorkoutBloc, WorkoutState>(
                  listener: (context, state) {
                    if (state is WorkoutCompleted) {
                      Navigator.pop(context);
                      ToastService.showSuccess('workout_saved'.tr());
                    }
                  },
                  builder: (context, state) {
                    if (state is! WorkoutInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_cameraController == null ||
                        !_cameraController!.value.isInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  _cameraController!.value.previewSize!.height,
                              height:
                                  _cameraController!.value.previewSize!.width,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        ),
                        if (state.currentFaults.isNotEmpty)
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.red.withOpacity(0.0),
                                      Colors.red.withOpacity(0.2),
                                      Colors.red.withOpacity(0.45),
                                    ],
                                    stops: const [0.0, 0.5, 0.7, 1.0],
                                    center: Alignment.center,
                                    radius: 0.85,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (state.pose != null)
                          CustomPaint(
                            painter: PosePainter(
                              pose: state.pose,
                              currentFaults: state.currentFaults,
                              imageSize: ui.Size(
                                _cameraController!.value.previewSize!.height,
                                _cameraController!.value.previewSize!.width,
                              ),
                              screenSize: MediaQuery.of(context).size,
                            ),
                          ),
                        _buildUIOverlay(state),
                        if (state.lastRepIsCorrect != null)
                          _buildRepFeedbackBackground(state.lastRepIsCorrect!),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildRepFeedbackBackground(bool isCorrect) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isCorrect ? Colors.green : Colors.red)
                        .withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: FaIcon(
                      isCorrect
                          ? FontAwesomeIcons.check
                          : FontAwesomeIcons.xmark,
                      color: Colors.white,
                      size: 100,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUIOverlay(WorkoutInProgress state) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getExerciseName(state.exerciseType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.flag,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.targetReps}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_cameras.length > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _switchCamera,
                              borderRadius: BorderRadius.circular(50),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(
                                  FontAwesomeIcons.cameraRotate,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 0),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.currentReps}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'reps'.tr().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (state.currentFaults.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: state.currentFaults
                    .map((fault) => Text(
                          _getFaultMessage(fault),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.red.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<WorkoutBloc>().add(const StopWorkout());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleStop,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'stop_workout'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExerciseName(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return 'exercise_squat'.tr();
      case ExerciseType.bicepsCurl:
        return 'exercise_biceps_curl'.tr();
      case ExerciseType.lateralRaise:
        return 'exercise_lateral_raise'.tr();
    }
  }

  String _getFaultMessage(String faultCode) {
    return 'fault_$faultCode'.tr();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }
}
