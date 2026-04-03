import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/features/camera/face_detection_service.dart';

/// Flow: Camera → Face detection (ML Kit) → Liveness (blink) → Show Capture button → Return path for backend.
enum _CameraFlowState {
  loading,
  scanning,
  livenessBlink,
  readyToCapture,
  error,
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.title = 'Take Photo'});

  final String title;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  _CameraFlowState _state = _CameraFlowState.loading;
  String? _error;
  String? _message;
  Timer? _captureTimer;
  bool _isProcessing = false;
  bool _isCapturingFinalPhoto = false;
  late FaceDetectionService _faceService;
  // Blink liveness: require eyes open → closed → open (consecutive frames to avoid photo spoof).
  int _consecutiveEyesOpen = 0;
  int _consecutiveEyesClosed = 0;
  bool _blinkClosedPhaseSeen = false;
  static const int _requiredOpenFrames = 2;
  static const int _requiredClosedFrames = 2;

  @override
  void initState() {
    super.initState();
    _faceService = FaceDetectionService();
    _initCamera();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _controller?.dispose();
    _faceService.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      final frontList = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      final camera = frontList.isNotEmpty ? frontList.first : _cameras.first;

      // iOS only supports BGRA for the preview/capture pipeline; JPEG is for Android.
      // Using JPEG on iOS can cause takePicture() to fail repeatedly (CameraException).
      final format =
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg;
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: format,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _state = _CameraFlowState.scanning;
        _message = 'Position your face in the frame';
      });
      _startCaptureLoop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CameraFlowState.error;
        _error = e.toString();
      });
    }
  }

  void _startCaptureLoop() {
    _captureTimer?.cancel();
    // iOS is stricter about back-to-back takePicture(); give the pipeline more time.
    final interval = Platform.isIOS
        ? const Duration(milliseconds: 900)
        : const Duration(milliseconds: 600);
    _captureTimer = Timer.periodic(interval, (_) => _captureAndAnalyze());
  }

  void _resetBlinkState() {
    _consecutiveEyesOpen = 0;
    _consecutiveEyesClosed = 0;
    _blinkClosedPhaseSeen = false;
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing ||
        !mounted) {
      return;
    }
    if (_state != _CameraFlowState.scanning &&
        _state != _CameraFlowState.livenessBlink) {
      return;
    }
    // Don't run when readyToCapture — camera stays open, user taps Capture

    _isProcessing = true;
    try {
      final file = await _controller!.takePicture();
      final result = await _faceService.processFile(file.path);

      if (!mounted) return;

      switch (_state) {
        case _CameraFlowState.scanning:
          if (result.isGoodForCapture) {
            _consecutiveEyesOpen = 0;
            _consecutiveEyesClosed = 0;
            _blinkClosedPhaseSeen = false;
            setState(() {
              _state = _CameraFlowState.livenessBlink;
              _message = 'Blink once to continue (prevents photo spoofing)';
            });
          } else if (result.faceCount == 0) {
            setState(() => _message = 'Position your face in the frame');
          } else if (result.faceCount > 1) {
            setState(() => _message = 'Only one person should be in frame');
          }
          break;
        case _CameraFlowState.livenessBlink:
          if (result.faceCount != 1) {
            _resetBlinkState();
            setState(
              () => _message = 'Keep your face in frame, then blink once',
            );
            break;
          }
          if (result.eyesOpen) {
            _consecutiveEyesClosed = 0;
            _consecutiveEyesOpen++;
            if (_blinkClosedPhaseSeen &&
                _consecutiveEyesOpen >= _requiredOpenFrames) {
              _captureTimer?.cancel();
              setState(() {
                _state = _CameraFlowState.readyToCapture;
                _message = 'Verification complete. Capturing photo...';
              });
              _isProcessing = false;
              _autoCaptureAfterVerification();
              return;
            }
            setState(
              () => _message = _blinkClosedPhaseSeen
                  ? 'Eyes open again — verifying...'
                  : 'Blink once to continue (prevents photo spoofing)',
            );
          } else if (result.eyesClosed) {
            _consecutiveEyesOpen = 0;
            _consecutiveEyesClosed++;
            if (_consecutiveEyesClosed >= _requiredClosedFrames) {
              _blinkClosedPhaseSeen = true;
            }
            setState(
              () => _message = _blinkClosedPhaseSeen
                  ? 'Now open your eyes'
                  : 'Blink once to continue',
            );
          } else {
            _consecutiveEyesOpen = 0;
            _consecutiveEyesClosed = 0;
            setState(() => _message = 'Blink once clearly to continue');
          }
          break;
        default:
          break;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('CameraPage _captureAndAnalyze: $e\n$st');
      }
    }
    _isProcessing = false;
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturingFinalPhoto) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isCapturingFinalPhoto = true;
    try {
      final file = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final fileName =
          'face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest = File('${dir.path}/$fileName');
      await File(file.path).copy(dest.path);
      if (!mounted) return;
      Navigator.of(context).pop<String?>(dest.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to capture photo${e is CameraException ? ': ${e.code}' : ''}',
            ),
          ),
        );
      }
    } finally {
      _isCapturingFinalPhoto = false;
    }
  }

  Future<void> _autoCaptureAfterVerification() async {
    if (_isCapturingFinalPhoto || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _onCapturePressed();
  }

  void _cancel() {
    Navigator.of(context).pop<String?>(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancel,
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_state == _CameraFlowState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Opening camera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_state == _CameraFlowState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera error',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _state = _CameraFlowState.loading;
                    _error = null;
                  });
                  _initCamera();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _cancel, child: const Text('Cancel')),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message ?? 'Position your face',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              if (_state == _CameraFlowState.readyToCapture &&
                  !_isCapturingFinalPhoto) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _onCapturePressed,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Capture'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
