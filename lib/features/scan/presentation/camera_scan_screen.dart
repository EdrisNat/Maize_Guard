import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/core/widgets/app_error_state.dart';
import 'package:maize_leaf_prediction/core/widgets/loading_overlay.dart';
import 'package:maize_leaf_prediction/features/results/presentation/result_screen.dart';
import 'package:maize_leaf_prediction/features/scan/presentation/image_editor_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen> {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _flashEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _isInitializing = false;
        _error = 'Camera permission denied.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _flashEnabled = !_flashEnabled;
      await _cameraController!.setFlashMode(
        _flashEnabled ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Flash unavailable')));
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || _isCapturing) return;
    try {
      setState(() => _isCapturing = true);
      final photo = await _cameraController!.takePicture();
      if (!mounted) return;
      // Navigate to image editor before running inference
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageEditorScreen(
            imagePath: photo.path,
            onConfirm: (editedPath) async {
              Navigator.of(context).pop(); // Close editor
              await _runInference(editedPath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _runInference(String imagePath) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const LoadingOverlay(message: 'Scoring leaf image offline...'),
    );
    try {
      final result =
          await ref.read(tfliteServiceProvider).runInference(imagePath);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imagePath: imagePath,
            prediction: result,
            saveToHistory: true,
          ),
        ),
      );
      ref.invalidate(scanHistoryProvider);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Inference error: $e')));
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guided camera scan')),
        body: AppErrorState(
          message: _error!,
          actionLabel: 'Open Settings',
          onAction: openAppSettings,
        ),
      );
    }
    if (_cameraController == null) {
      return const Scaffold(
        body: AppErrorState(message: 'Camera unavailable for this device.'),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available height for guide box
                // Account for: padding (40), header (48), instructions (~90), spacer, badges (50), button (96), gaps
                final availableHeight = constraints.maxHeight;
                final headerHeight = 48.0;
                final instructionHeight = 90.0;
                final badgeAndButtonHeight = 166.0; // badges + button + gaps
                final padding = 56.0; // vertical padding + gaps
                final guideMaxHeight = (availableHeight - headerHeight - instructionHeight - badgeAndButtonHeight - padding).clamp(120.0, 320.0);
                
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: _toggleFlash,
                            icon: Icon(
                              _flashEnabled
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.34),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tips_and_updates_rounded,
                                color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Fill the frame with one leaf. Use daylight, avoid shadows, and hold steady before capture.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.34),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: guideMaxHeight,
                                maxWidth: guideMaxHeight * 0.78,
                              ),
                              child: AspectRatio(
                                aspectRatio: 0.78,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border:
                                        Border.all(color: Colors.white70, width: 2),
                                  ),
                                  child: Stack(
                                    children: const [
                                      Positioned(
                                          top: 18, left: 18, child: _CornerGuide()),
                                      Positioned(
                                          top: 18,
                                          right: 18,
                                          child: RotatedBox(
                                              quarterTurns: 1,
                                              child: _CornerGuide())),
                                      Positioned(
                                          bottom: 18,
                                          left: 18,
                                          child: RotatedBox(
                                              quarterTurns: 3,
                                              child: _CornerGuide())),
                                      Positioned(
                                          bottom: 18,
                                          right: 18,
                                          child: RotatedBox(
                                              quarterTurns: 2,
                                              child: _CornerGuide())),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _GuideBadge(
                                    icon: Icons.center_focus_strong_rounded,
                                    label: 'Center leaf'),
                                _GuideBadge(
                                    icon: Icons.wb_sunny_outlined,
                                    label: 'Bright light'),
                                _GuideBadge(
                                    icon: Icons.pan_tool_alt_rounded,
                                    label: 'Hold still'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FloatingActionButton.large(
                              backgroundColor: AppTheme.gold,
                              foregroundColor: AppTheme.forest,
                              onPressed: _captureAndScan,
                              child: _isCapturing
                                  ? const CircularProgressIndicator(color: AppTheme.forest)
                                  : const Icon(Icons.camera_alt_rounded, size: 34),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBadge extends StatelessWidget {
  const _GuideBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _CornerGuide extends StatelessWidget {
  const _CornerGuide();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
            top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
          ),
        ),
      ),
    );
  }
}
