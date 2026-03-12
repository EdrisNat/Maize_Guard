import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    required this.imagePath,
    required this.onConfirm,
    super.key,
  });

  final String imagePath;
  final void Function(String editedImagePath) onConfirm;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _viewerKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _isCropping = false;
  bool _isProcessing = false;
  bool _isZoomed = false;
  
  // Crop rect (normalized 0-1)
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  
  // Track zoom state
  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05; // Consider zoomed if scale > 1.05
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }
  
  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _resetEdits() {
    setState(() {
      _isZoomed = false;
      _brightness = 0.0;
      _contrast = 1.0;
      _transformController.value = Matrix4.identity();
      _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
      _isCropping = false;
    });
  }

  Future<String> _processAndSaveImage() async {
    // Load original image
    final bytes = await File(widget.imagePath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    // Apply zoom crop if zoomed
    if (_isZoomed) {
      final matrix = _transformController.value;
      final scale = matrix.getMaxScaleOnAxis();
      
      // Get the translation (pan) values
      final tx = matrix.getTranslation().x;
      final ty = matrix.getTranslation().y;
      
      // Calculate viewport size (assume square viewport for simplicity)
      final viewportSize = _viewerKey.currentContext?.size;
      if (viewportSize != null) {
        // Calculate the visible portion of the image
        final imgAspect = image.width / image.height;
        final viewAspect = viewportSize.width / viewportSize.height;
        
        double displayW, displayH;
        if (imgAspect > viewAspect) {
          displayW = viewportSize.width;
          displayH = viewportSize.width / imgAspect;
        } else {
          displayH = viewportSize.height;
          displayW = viewportSize.height * imgAspect;
        }
        
        // Scale factor from display to actual image pixels
        final pixelScale = image.width / displayW;
        
        // Calculate visible region in image coordinates
        final visibleLeft = (-tx / scale) * pixelScale;
        final visibleTop = (-ty / scale) * pixelScale;
        final visibleWidth = (viewportSize.width / scale) * pixelScale;
        final visibleHeight = (viewportSize.height / scale) * pixelScale;
        
        // Clamp values to image bounds
        final x = visibleLeft.clamp(0, image.width - 1).round();
        final y = visibleTop.clamp(0, image.height - 1).round();
        final w = visibleWidth.clamp(1, image.width - x).round();
        final h = visibleHeight.clamp(1, image.height - y).round();
        
        if (w > 10 && h > 10) {
          image = img.copyCrop(image, x: x, y: y, width: w, height: h);
        }
      }
    }

    // Apply manual crop if active (on top of zoom crop)
    if (_isCropping) {
      final x = (_cropRect.left * image.width).round();
      final y = (_cropRect.top * image.height).round();
      final w = (_cropRect.width * image.width).round();
      final h = (_cropRect.height * image.height).round();
      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }

    // Apply brightness and contrast with safe ranges
    if (_brightness != 0.0 || _contrast != 1.0) {
      // Gentle adjustment: brightness range -15 to +15, contrast 0.85 to 1.15
      // This prevents extreme black/white wash-out
      final brightnessAdjust = (_brightness * 30).round(); // -15 to +15 range
      
      // Apply color adjustment per pixel for better control
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          
          // Get RGB values
          var r = pixel.r.toDouble();
          var g = pixel.g.toDouble();
          var b = pixel.b.toDouble();
          
          // Apply contrast (centered around 128)
          r = ((r - 128) * _contrast + 128);
          g = ((g - 128) * _contrast + 128);
          b = ((b - 128) * _contrast + 128);
          
          // Apply brightness
          r = r + brightnessAdjust;
          g = g + brightnessAdjust;
          b = b + brightnessAdjust;
          
          // Clamp to valid range
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);
          
          image.setPixelRgba(x, y, r.round(), g.round(), b.round(), pixel.a.toInt());
        }
      }
    }

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputPath = p.join(tempDir.path, fileName);
    
    final outputBytes = img.encodeJpg(image, quality: 95);
    await File(outputPath).writeAsBytes(outputBytes);
    
    return outputPath;
  }

  Future<void> _onConfirm() async {
    setState(() => _isProcessing = true);
    try {
      // Check if any edits were made (including zoom)
      final hasEdits = _brightness != 0.0 || _contrast != 1.0 || _isCropping || _isZoomed;
      
      if (hasEdits) {
        final editedPath = await _processAndSaveImage();
        widget.onConfirm(editedPath);
      } else {
        widget.onConfirm(widget.imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  ColorFilter get _colorFilter {
    // Proper brightness/contrast formula
    // Brightness: add offset (range -30 to +30)
    // Contrast: scale around midpoint (128)
    final b = _brightness * 60; // -30 to +30
    final c = _contrast;
    
    // Contrast matrix formula: (color - 128) * contrast + 128
    // This translates to: color * contrast + 128 * (1 - contrast)
    final offset = 128 * (1 - c) + b;
    
    return ColorFilter.matrix(<double>[
      c, 0, 0, 0, offset,
      0, c, 0, 0, offset,
      0, 0, c, 0, offset,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _EditorIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Edit Image',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _EditorIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _resetEdits,
                  ),
                ],
              ),
            ),
            
            // Image preview area
            Expanded(
              key: _viewerKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Zoomable/pannable image with filters
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    clipBehavior: Clip.hardEdge,
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: _colorFilter,
                        child: Image.file(
                          File(widget.imagePath),
                          key: _imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Crop overlay
                  if (_isCropping)
                    Positioned.fill(
                      child: _CropOverlay(
                        cropRect: _cropRect,
                        onCropRectChanged: (rect) {
                          setState(() => _cropRect = rect);
                        },
                      ),
                    ),
                ],
              ),
            ),
            
            // Editing controls panel
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickActionButton(
                        icon: Icons.zoom_in_rounded,
                        label: 'Zoom',
                        isActive: _isZoomed,
                        onTap: () {
                          // Double zoom
                          final currentScale = _transformController.value.getMaxScaleOnAxis();
                          final newScale = (currentScale * 1.5).clamp(1.0, 4.0);
                          _transformController.value = Matrix4.identity()..scale(newScale);
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.crop_rounded,
                        label: 'Crop',
                        isActive: _isCropping,
                        onTap: () {
                          setState(() => _isCropping = !_isCropping);
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Bright',
                        isActive: _brightness != 0.0,
                        onTap: () {
                          // Toggle brightness preset
                          setState(() {
                            _brightness = _brightness == 0.0 ? 0.2 : 0.0;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Brightness slider
                  _SliderControl(
                    icon: Icons.brightness_6_rounded,
                    label: 'Brightness',
                    value: _brightness,
                    min: -0.5,
                    max: 0.5,
                    onChanged: (value) => setState(() => _brightness = value),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Contrast slider
                  _SliderControl(
                    icon: Icons.contrast_rounded,
                    label: 'Contrast',
                    value: _contrast,
                    min: 0.5,
                    max: 1.5,
                    onChanged: (value) => setState(() => _contrast = value),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.forest,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.forest,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isProcessing ? 'Processing...' : 'Analyze with AI',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.gold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: AppTheme.gold, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.gold : Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.gold : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  const _SliderControl({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.gold,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: AppTheme.gold,
              overlayColor: AppTheme.gold.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${((value - (min + max) / 2) * 100 / ((max - min) / 2)).round()}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _CropOverlay extends StatefulWidget {
  const _CropOverlay({
    required this.cropRect,
    required this.onCropRectChanged,
  });

  final Rect cropRect;
  final ValueChanged<Rect> onCropRectChanged;

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<_CropOverlay> {
  int? _activeHandle;
  Offset? _startOffset;
  Rect? _startRect;

  void _onPanStart(DragStartDetails details, int handle) {
    _activeHandle = handle;
    _startOffset = details.localPosition;
    _startRect = widget.cropRect;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle == null || _startRect == null) return;
    
    final size = context.size ?? const Size(300, 400);
    final delta = Offset(
      details.localPosition.dx - _startOffset!.dx,
      details.localPosition.dy - _startOffset!.dy,
    );
    final normalizedDelta = Offset(delta.dx / size.width, delta.dy / size.height);
    
    var newRect = _startRect!;
    
    switch (_activeHandle) {
      case 0: // Top-left
        newRect = Rect.fromLTRB(
          (newRect.left + normalizedDelta.dx).clamp(0.0, newRect.right - 0.1),
          (newRect.top + normalizedDelta.dy).clamp(0.0, newRect.bottom - 0.1),
          newRect.right,
          newRect.bottom,
        );
        break;
      case 1: // Top-right
        newRect = Rect.fromLTRB(
          newRect.left,
          (newRect.top + normalizedDelta.dy).clamp(0.0, newRect.bottom - 0.1),
          (newRect.right + normalizedDelta.dx).clamp(newRect.left + 0.1, 1.0),
          newRect.bottom,
        );
        break;
      case 2: // Bottom-left
        newRect = Rect.fromLTRB(
          (newRect.left + normalizedDelta.dx).clamp(0.0, newRect.right - 0.1),
          newRect.top,
          newRect.right,
          (newRect.bottom + normalizedDelta.dy).clamp(newRect.top + 0.1, 1.0),
        );
        break;
      case 3: // Bottom-right
        newRect = Rect.fromLTRB(
          newRect.left,
          newRect.top,
          (newRect.right + normalizedDelta.dx).clamp(newRect.left + 0.1, 1.0),
          (newRect.bottom + normalizedDelta.dy).clamp(newRect.top + 0.1, 1.0),
        );
        break;
      case 4: // Center - move entire rect
        final dxClamped = normalizedDelta.dx.clamp(-newRect.left, 1.0 - newRect.right);
        final dyClamped = normalizedDelta.dy.clamp(-newRect.top, 1.0 - newRect.bottom);
        newRect = newRect.translate(dxClamped, dyClamped);
        break;
    }
    
    widget.onCropRectChanged(newRect);
  }

  void _onPanEnd(DragEndDetails details) {
    _activeHandle = null;
    _startOffset = null;
    _startRect = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rect = Rect.fromLTWH(
          widget.cropRect.left * constraints.maxWidth,
          widget.cropRect.top * constraints.maxHeight,
          widget.cropRect.width * constraints.maxWidth,
          widget.cropRect.height * constraints.maxHeight,
        );
        
        return Stack(
          children: [
            // Dimmed overlay
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CropOverlayPainter(rect),
            ),
            
            // Crop frame
            Positioned.fromRect(
              rect: rect,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
              ),
            ),
            
            // Grid lines
            Positioned.fromRect(
              rect: rect,
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
            
            // Corner handles
            ..._buildHandles(rect),
            
            // Center drag area
            Positioned.fromRect(
              rect: rect.deflate(30),
              child: GestureDetector(
                onPanStart: (d) => _onPanStart(d, 4),
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildHandles(Rect rect) {
    const handleSize = 24.0;
    final positions = [
      Offset(rect.left, rect.top), // Top-left
      Offset(rect.right, rect.top), // Top-right
      Offset(rect.left, rect.bottom), // Bottom-left
      Offset(rect.right, rect.bottom), // Bottom-right
    ];
    
    return positions.asMap().entries.map((entry) {
      final index = entry.key;
      final pos = entry.value;
      
      return Positioned(
        left: pos.dx - handleSize / 2,
        top: pos.dy - handleSize / 2,
        child: GestureDetector(
          onPanStart: (d) => _onPanStart(d, index),
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter(this.cropRect);
  
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    
    // Draw dimmed areas around crop rect
    // Top
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, cropRect.top),
      paint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTRB(0, cropRect.bottom, size.width, size.height),
      paint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom),
      paint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return cropRect != oldDelegate.cropRect;
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5;
    
    // Draw rule of thirds grid
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
