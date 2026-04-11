import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/features/camera/camera_capture_config.dart';
import 'package:flutter_synergy/features/camera/face_detection_ios.dart';
import 'package:flutter_synergy/features/camera/face_detection_service.dart';

/// Flow: Camera → Face detection → Liveness (iOS: close then open; Android: blink) → Capture.
enum _CameraFlowState {
  loading,
  scanning,
  livenessEyes,
  readyToCapture,
  error,
}

/// Last iOS BGRA preview frame (copied; plugin may reuse buffers).
final class _IosBgraSnapshot {
  const _IosBgraSnapshot({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
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

  /// Bumped on dispose so in-flight [takePicture] / analysis does not touch a disposed controller.
  int _cameraGeneration = 0;
  late FaceDetectionService _faceService;
  late CameraCaptureConfig _captureConfig;
  // Eye liveness: open → brief closed (blink) → open again; consecutive frames reduce false triggers.
  int _consecutiveEyesOpen = 0;
  int _consecutiveEyesClosed = 0;
  bool _closedEyesConfirmed = false;

  /// iOS: brief face loss during eye check should not wipe progress.
  int _iosLivenessBadFaceFrames = 0;

  /// iOS: max avg(left,right) since liveness started — closed eyes = dip below peak when Vision flags lag.
  double _iosLivenessOpennessPeak = 0;

  _IosBgraSnapshot? _iosPreviewFrame;

  /// Silent final image path (BGRA → JPEG on native), if snapshot succeeded.
  String? _pendingFinalJpegPath;

  /// “Open again” after a blink: iOS BGRA is fast; ML Kit stills need an extra frame sometimes.
  int get _requiredOpenFrames => Platform.isIOS ? 1 : 2;
  /// Single closed frame is enough to register a blink; supplemental heuristics add robustness.
  int get _requiredClosedFrames => 1;

  /// During eye liveness, analyze often enough to catch a blink (iOS: BGRA; Android: stills).
  static const Duration _tightLivenessAnalysisInterval = Duration(
    milliseconds: 250,
  );

  Duration _periodicAnalysisInterval() {
    if (_state == _CameraFlowState.livenessEyes) {
      if (Platform.isIOS || Platform.isAndroid) {
        return _tightLivenessAnalysisInterval;
      }
    }
    return _captureConfig.analysisInterval;
  }

  void _restartPeriodicAnalysisTimer() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(
      _periodicAnalysisInterval(),
      (_) => unawaited(_captureAndAnalyze()),
    );
  }

  @override
  void initState() {
    super.initState();
    _faceService = FaceDetectionService();
    _initCamera();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _cameraGeneration++;
    final released = _controller;
    _controller = null;
    _faceService.close();
    super.dispose();
    if (released != null) {
      unawaited(_disposeControllerWhenIdle(released));
    }
  }

  /// [takePicture] is async; disposing the controller on the next microtask
  /// races in-flight captures and triggers "used after being disposed".
  Future<void> _disposeControllerWhenIdle(CameraController c) async {
    const step = Duration(milliseconds: 10);
    for (var i = 0; i < 200 && (_isProcessing || _isCapturingFinalPhoto); i++) {
      await Future<void>.delayed(step);
    }
    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      _captureConfig = CameraCaptureConfig.forCurrentPlatform();
      _cameras = await availableCameras();
      final frontList = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      final camera = frontList.isNotEmpty ? frontList.first : _cameras.first;

      final cfg = _captureConfig;
      final controller = CameraController(
        camera,
        cfg.resolutionPreset,
        enableAudio: cfg.enableAudio,
        imageFormatGroup: cfg.imageFormatGroup,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (cfg.lockPortraitOnIos) {
        try {
          await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        } catch (_) {
          // Simulator or devices that reject orientation lock — non-fatal.
        }
      }
      if (Platform.isIOS && controller.supportsImageStreaming()) {
        try {
          await controller.startImageStream((CameraImage image) {
            if (image.planes.length != 1) return;
            if (image.format.group != ImageFormatGroup.bgra8888) return;
            final plane = image.planes.first;
            _iosPreviewFrame = _IosBgraSnapshot(
              bytes: Uint8List.fromList(plane.bytes),
              width: image.width,
              height: image.height,
              bytesPerRow: plane.bytesPerRow,
            );
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('CameraPage iOS startImageStream: $e');
          }
        }
      }
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
    // [Timer.periodic] waits [analysisInterval] before the first tick. Android:
    // analyze right away. iOS: delay the first still so preview / AVFoundation
    // can settle (reduces Fig -17281 and feels less like rapid auto-capture).
    if (Platform.isIOS) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          unawaited(_captureAndAnalyze());
        }),
      );
    } else {
      unawaited(_captureAndAnalyze());
    }
    _restartPeriodicAnalysisTimer();
  }

  void _resetEyeLivenessState() {
    _consecutiveEyesOpen = 0;
    _consecutiveEyesClosed = 0;
    _closedEyesConfirmed = false;
    _iosLivenessBadFaceFrames = 0;
    _iosLivenessOpennessPeak = 0;
  }

  /// Periodic face check: iOS and Android use different capture/error handling.
  Future<void> _captureAndAnalyze() async {
    final gen = _cameraGeneration;
    if (!_canStartFaceAnalysis(gen)) return;

    _isProcessing = true;
    try {
      if (Platform.isIOS) {
        await _captureAndAnalyzeIos(gen);
      } else {
        await _captureAndAnalyzeAndroid(gen);
      }
    } catch (e, st) {
      if (Platform.isIOS) {
        _onIosAnalysisError(e, st);
      } else {
        _onAndroidAnalysisError(e, st);
      }
    } finally {
      _isProcessing = false;
    }
  }

  bool _canStartFaceAnalysis(int gen) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing ||
        !mounted ||
        gen != _cameraGeneration) {
      return false;
    }
    if (_state != _CameraFlowState.scanning &&
        _state != _CameraFlowState.livenessEyes) {
      return false;
    }
    return true;
  }

  /// iOS: still capture + Vision — user-visible errors when AVFoundation is busy.
  Future<void> _captureAndAnalyzeIos(int gen) async {
    final result = await _acquireFaceDetectionResult(
      gen,
      onTakePictureFailure: _notifyIosCameraBusyDuringAnalysis,
    );
    if (result == null || !mounted || gen != _cameraGeneration) return;
    _applyFaceDetectionStateMachine(result);
  }

  /// Android: still capture + ML Kit — lighter error surface (logs only).
  Future<void> _captureAndAnalyzeAndroid(int gen) async {
    final result = await _acquireFaceDetectionResult(
      gen,
      onTakePictureFailure: _notifyAndroidTakePictureFailedDuringAnalysis,
    );
    if (result == null || !mounted || gen != _cameraGeneration) return;
    _applyFaceDetectionStateMachine(result);
  }

  /// iOS: silent BGRA → Vision when preview stream is running; otherwise (or
  /// Android) [takePicture] + file pipeline.
  Future<FaceDetectionResult?> _acquireFaceDetectionResult(
    int gen, {
    required void Function() onTakePictureFailure,
  }) async {
    final c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        gen != _cameraGeneration ||
        !mounted) {
      return null;
    }

    if (Platform.isIOS && c.value.isStreamingImages) {
      final snap = _iosPreviewFrame;
      if (snap != null && snap.bytes.length > 512) {
        try {
          final previewResult = await _faceService.processBgra8888Preview(
            bytes: snap.bytes,
            width: snap.width,
            height: snap.height,
            bytesPerRow: snap.bytesPerRow,
          );
          if (previewResult != null && mounted && gen == _cameraGeneration) {
            return previewResult;
          }
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('CameraPage BGRA Vision preview: $e\n$st');
          }
        }
      }
      // Stream is on but no frame yet — do not call [takePicture] (fails while streaming).
      return null;
    }

    final XFile file;
    try {
      file = await c.takePicture();
    } on CameraException catch (e) {
      if (kDebugMode) {
        debugPrint('CameraPage takePicture (analysis): $e');
      }
      if (!mounted || gen != _cameraGeneration) return null;
      onTakePictureFailure();
      return null;
    }
    if (!mounted || gen != _cameraGeneration) return null;

    final cooldown = _captureConfig.postStillCaptureCooldown;
    if (cooldown > Duration.zero) {
      await Future<void>.delayed(cooldown);
      if (!mounted || gen != _cameraGeneration) return null;
    }

    return _faceService.processFile(file.path);
  }

  void _notifyIosCameraBusyDuringAnalysis() {
    setState(() {
      _message =
          'Camera is busy. Please wait a moment and hold your face in frame.';
    });
  }

  void _notifyAndroidTakePictureFailedDuringAnalysis() {
    // Previously no UI hint; keep analysis loop quiet on Android.
  }

  void _onIosAnalysisError(Object e, StackTrace st) {
    if (kDebugMode) {
      debugPrint('CameraPage iOS analysis: $e\n$st');
    }
    if (mounted) {
      setState(() {
        _message =
            'Could not capture frame. Ensure camera access is allowed and try again.';
      });
    }
  }

  void _onAndroidAnalysisError(Object e, StackTrace st) {
    if (kDebugMode) {
      debugPrint('CameraPage Android analysis: $e\n$st');
    }
  }

  /// Scanning / eye-liveness transitions (frame counts differ by platform).
  void _applyFaceDetectionStateMachine(FaceDetectionResult result) {
    switch (_state) {
      case _CameraFlowState.scanning:
        _applyScanningPhase(result);
        break;
      case _CameraFlowState.livenessEyes:
        _applyLivenessPhase(result);
        break;
      default:
        break;
    }
  }

  /// Extra closed signal when Vision [eyesClosed] is false but scores dropped from baseline.
  bool _iosLivenessLooksClosedFromScores(FaceDetectionResult result) {
    final l = result.leftEyeOpenProbability;
    final r = result.rightEyeOpenProbability;
    if (l == null || r == null) return true;
    final avg = (l + r) * 0.5;
    final lo = math.min(l, r);
    final hi = math.max(l, r);
    if (avg < 0.42) return true;
    if (lo < 0.30) return true;
    if (avg < 0.52 && hi < 0.50 && lo < 0.40) return true;
    return false;
  }

  /// Registers closed eyes when scores dip from a recent peak if flags lag.
  bool _iosLivenessRegisterClosedFromOpennessDrop(FaceDetectionResult result) {
    final l = result.leftEyeOpenProbability;
    final r = result.rightEyeOpenProbability;
    if (l == null || r == null) return false;
    final avg = (l + r) * 0.5;
    if (avg > _iosLivenessOpennessPeak) {
      _iosLivenessOpennessPeak = avg;
    }
    final peak = _iosLivenessOpennessPeak;
    final drop = peak - avg;
    if (peak < 0.085) return false;
    if (drop < 0.030) return false;
    if (avg > 0.52) return false;
    _consecutiveEyesOpen = 0;
    _consecutiveEyesClosed++;
    if (_consecutiveEyesClosed >= _requiredClosedFrames) {
      _closedEyesConfirmed = true;
    }
    setState(
      () => _message = _closedEyesConfirmed
          ? (Platform.isAndroid
              ? 'Keep your eyes open'
              : 'Now open your eyes')
          : (Platform.isAndroid
              ? 'Blink once'
              : 'Close your eyes and hold for a moment'),
    );
    return true;
  }

  void _applyScanningPhase(FaceDetectionResult result) {
    if (result.isGoodForCapture) {
      _resetEyeLivenessState();
      setState(() {
        _state = _CameraFlowState.livenessEyes;
        _message = Platform.isAndroid
            ? 'Blink once when you\'re ready'
            : 'Close your eyes and hold for a moment';
      });
      if (Platform.isIOS || Platform.isAndroid) {
        _restartPeriodicAnalysisTimer();
        unawaited(_captureAndAnalyze());
      }
      return;
    }
    if (result.faceCount == 0) {
      setState(() => _message = 'Position your face in the frame');
      return;
    }
    if (result.faceCount > 1) {
      setState(() => _message = 'Only one person should be in frame');
      return;
    }
    if (result.faceCount == 1) {
      if (!result.classificationAvailable) {
        setState(() => _message = 'Hold still — analyzing face');
      } else if (!result.eyesOpen) {
        setState(() => _message = 'Look at the camera with eyes open');
      } else {
        setState(() => _message = 'Move a little closer to the camera');
      }
    }
  }

  void _applyLivenessPhase(FaceDetectionResult result) {
    if (result.faceCount != 1) {
      _iosLivenessBadFaceFrames++;
      if (_iosLivenessBadFaceFrames >= 5) {
        _resetEyeLivenessState();
        setState(
          () => _message = Platform.isAndroid
              ? 'Stay in frame, then blink when ready'
              : 'Keep your face in frame, then close your eyes',
        );
      } else {
        setState(
          () => _message = Platform.isAndroid
              ? 'Stay in frame'
              : 'Stay in frame — close your eyes when ready',
        );
      }
      return;
    }
    _iosLivenessBadFaceFrames = 0;

    if (!result.classificationAvailable) {
      setState(
        () => _message = 'Keep your face visible — we need to see your eyes',
      );
      return;
    }
    // Prefer closed before open. Score-based closed only until we’ve confirmed — otherwise
    // “open again” would keep matching supplemental thresholds and never finish.
    final closedNow = result.eyesClosed ||
        (!_closedEyesConfirmed &&
            _iosLivenessLooksClosedFromScores(result));
    if (closedNow) {
      _consecutiveEyesOpen = 0;
      _consecutiveEyesClosed++;
      if (_consecutiveEyesClosed >= _requiredClosedFrames) {
        _closedEyesConfirmed = true;
      }
      setState(
        () => _message = _closedEyesConfirmed
            ? (Platform.isAndroid
                ? 'Keep your eyes open'
                : 'Now open your eyes')
            : (Platform.isAndroid
                ? 'Blink once'
                : 'Close your eyes and hold for a moment'),
      );
      return;
    }
    if (!_closedEyesConfirmed &&
        _iosLivenessRegisterClosedFromOpennessDrop(result)) {
      return;
    }
    final openNow = result.eyesOpen ||
        (_closedEyesConfirmed &&
            !_iosLivenessLooksClosedFromScores(result));
    if (openNow) {
      _consecutiveEyesClosed = 0;
      _consecutiveEyesOpen++;
      if (_closedEyesConfirmed &&
          _consecutiveEyesOpen >= _requiredOpenFrames) {
        _transitionToReadyToCapture();
        return;
      }
      setState(
        () => _message = _closedEyesConfirmed
            ? 'Keep your eyes open — finishing…'
            : (Platform.isAndroid
                ? 'Blink once'
                : 'Close your eyes and hold for a moment'),
      );
      return;
    }
    if (Platform.isIOS) {
      setState(
        () => _message =
            'Close your eyes, then open them when we say so',
      );
      return;
    }
    _consecutiveEyesOpen = 0;
    _consecutiveEyesClosed = 0;
    setState(
      () => _message = Platform.isAndroid
          ? 'Blink once when you\'re ready'
          : 'Close your eyes, then open them when prompted',
    );
  }

  void _transitionToReadyToCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    if (Platform.isIOS) {
      unawaited(_transitionToReadyToCaptureIos());
    } else {
      setState(() {
        _state = _CameraFlowState.readyToCapture;
        _message = _readyToCaptureMessage();
      });
      _maybeAutoCaptureAfterVerification();
    }
  }

  Future<void> _stopIosImageStreamIfNeeded() async {
    final c = _controller;
    if (c == null || !c.value.isStreamingImages) return;
    try {
      await c.stopImageStream();
    } catch (_) {}
    _iosPreviewFrame = null;
  }

  Future<void> _transitionToReadyToCaptureIos() async {
    final gen = _cameraGeneration;
    final snap = _iosPreviewFrame;
    await _stopIosImageStreamIfNeeded();
    if (!mounted || gen != _cameraGeneration) return;

    String? pending;
    if (snap != null && snap.bytes.length > 512) {
      pending = await FaceDetectionServiceIos.writeBgraSnapshotToTempJpeg(
        bytes: snap.bytes,
        width: snap.width,
        height: snap.height,
        bytesPerRow: snap.bytesPerRow,
      );
    }
    if (!mounted || gen != _cameraGeneration) {
      if (pending != null) {
        try {
          await File(pending).delete();
        } catch (_) {}
      }
      return;
    }
    _pendingFinalJpegPath = pending;
    setState(() {
      _state = _CameraFlowState.readyToCapture;
      _message = _readyToCaptureMessage();
    });
    _maybeAutoCaptureAfterVerification();
  }

  String _readyToCaptureMessage() {
    return _captureConfig.autoCaptureAfterVerification
        ? 'Verification complete. Capturing photo...'
        : 'Verification complete. Tap Capture to take your photo';
  }

  void _maybeAutoCaptureAfterVerification() {
    if (_captureConfig.autoCaptureAfterVerification) {
      _autoCaptureAfterVerification();
    }
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturingFinalPhoto) return;
    final gen = _cameraGeneration;
    final c = _controller;
    if (c == null || !c.value.isInitialized || gen != _cameraGeneration) return;
    _isCapturingFinalPhoto = true;
    try {
      await _stopIosImageStreamIfNeeded();
      final pending = _pendingFinalJpegPath;
      _pendingFinalJpegPath = null;
      if (pending != null) {
        final src = File(pending);
        if (await src.exists()) {
          final dir = await getTemporaryDirectory();
          final dest = File(
            '${dir.path}/face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await src.copy(dest.path);
          try {
            await src.delete();
          } catch (_) {}
          if (!mounted || gen != _cameraGeneration) return;
          Navigator.of(context).pop<String?>(dest.path);
          return;
        }
      }

      final file = await c.takePicture();
      if (!mounted || gen != _cameraGeneration) return;
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
    final gen = _cameraGeneration;
    if (_isCapturingFinalPhoto || !mounted || gen != _cameraGeneration) return;
    final settle = Platform.isIOS
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 250);
    await Future<void>.delayed(settle);
    if (!mounted || gen != _cameraGeneration) return;
    await _onCapturePressed();
  }

  void _cancel() {
    final pending = _pendingFinalJpegPath;
    _pendingFinalJpegPath = null;
    if (pending != null) {
      unawaited(
        Future<void>(() async {
          try {
            await File(pending).delete();
          } catch (_) {}
        }),
      );
    }
    Navigator.of(context).pop<String?>(null);
  }

  /// Same orientation rule as [CameraPreview] so width/height matches its [AspectRatio].
  DeviceOrientation _applicableCameraOrientation(CameraController c) {
    return c.value.isRecordingVideo
        ? c.value.recordingOrientation!
        : (c.value.previewPauseOrientation ??
            c.value.lockedCaptureOrientation ??
            c.value.deviceOrientation);
  }

  bool _isCameraLandscape(CameraController c) {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ].contains(_applicableCameraOrientation(c));
  }

  /// Display width / height for the live preview (matches [CameraPreview]).
  double _cameraPreviewDisplayAspectRatio(CameraController c) {
    final ar = c.value.aspectRatio;
    return _isCameraLandscape(c) ? ar : 1 / ar;
  }

  /// Fills the stack without stretching the texture (uniform scale, may crop).
  Widget _buildCameraPreviewLayer() {
    final controller = _controller!;
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cw = constraints.maxWidth;
              final pa = _cameraPreviewDisplayAspectRatio(controller);
              if (pa <= 0 || !pa.isFinite) {
                return CameraPreview(controller);
              }
              return FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: cw,
                  height: cw / pa,
                  child: CameraPreview(controller),
                ),
              );
            },
          ),
        );
      },
    );
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
        Positioned.fill(child: _buildCameraPreviewLayer()),
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
