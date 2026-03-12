import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:maize_leaf_prediction/core/utils/date_time_formatter.dart';
import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PredictionReportInput {
  const PredictionReportInput({
    required this.imagePath,
    required this.predictedLabel,
    required this.confidence,
    required this.classProbabilities,
    required this.guidance,
    required this.timestamp,
    required this.modelVersion,
    required this.catalogVersion,
    required this.diseaseSummary,
    required this.qualityScore,
    this.farmerName,
    this.farmerLocation,
  });

  final String imagePath;
  final String predictedLabel;
  final double confidence;
  final Map<String, double> classProbabilities;
  final List<String> guidance;
  final DateTime timestamp;
  final String modelVersion;
  final String catalogVersion;
  final String diseaseSummary;
  final double qualityScore;
  final String? farmerName;
  final String? farmerLocation;
}

class ReportService {
  /// Export report to default reports directory
  static Future<File> exportPredictionReport(
      PredictionReportInput input) async {
    final baseDir = await _resolveBaseDirectory();
    final reportsDir = Directory(p.join(baseDir.path, 'reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    return _exportToDirectory(input, reportsDir.path);
  }

  /// Export report to a custom directory
  static Future<File> exportPredictionReportToPath(
      PredictionReportInput input, String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _exportToDirectory(input, directoryPath);
  }

  static Future<File> _exportToDirectory(
      PredictionReportInput input, String directoryPath) async {
    final safeLabel =
        input.predictedLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename =
        'maize_report_${safeLabel}_${input.timestamp.millisecondsSinceEpoch}.pdf';
    final reportFile = File(p.join(directoryPath, filename));

    final pdfBytes = await _buildPdf(input);
    await reportFile.writeAsBytes(pdfBytes, flush: true);
    return reportFile;
  }

  static Future<Uint8List> _buildPdf(PredictionReportInput input) async {
    final sorted = input.classProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Uint8List? jpgBytes;
    int imageWidth = 0;
    int imageHeight = 0;
    try {
      final originalBytes = await File(input.imagePath).readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 280);
        jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        imageWidth = resized.width;
        imageHeight = resized.height;
      }
    } catch (_) {
      jpgBytes = null;
    }

    final content = StringBuffer();
    var cursorY = 792.0;
    
    // Page dimensions
    const pageWidth = 595.0;
    const pageHeight = 842.0;
    const marginLeft = 40.0;
    const marginRight = 40.0;
    const contentWidth = pageWidth - marginLeft - marginRight;

    // Color definitions (RGB 0-1)
    void setColor(double r, double g, double b) {
      content.writeln('${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)} rg');
    }
    
    void setStrokeColor(double r, double g, double b) {
      content.writeln('${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)} RG');
    }

    void drawRect(double x, double y, double w, double h, {bool fill = true, bool stroke = false}) {
      content.writeln('${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} ${w.toStringAsFixed(1)} ${h.toStringAsFixed(1)} re');
      if (fill && stroke) {
        content.writeln('B');
      } else if (fill) {
        content.writeln('f');
      } else if (stroke) {
        content.writeln('S');
      }
    }

    void drawText(String text, double x, double y, double size, {String color = 'dark'}) {
      switch (color) {
        case 'white':
          content.writeln('1 1 1 rg');
          break;
        case 'green':
          content.writeln('0.11 0.37 0.13 rg');
          break;
        case 'gold':
          content.writeln('0.76 0.60 0.20 rg');
          break;
        case 'gray':
          content.writeln('0.45 0.45 0.45 rg');
          break;
        case 'lightgray':
          content.writeln('0.6 0.6 0.6 rg');
          break;
        default:
          content.writeln('0.15 0.15 0.15 rg');
      }
      content
        ..writeln('BT')
        ..writeln('/F1 ${size.toStringAsFixed(1)} Tf')
        ..writeln('${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} Td')
        ..writeln('(${_escapePdfText(text)}) Tj')
        ..writeln('ET');
    }

    List<String> wrapText(String text, int maxChars) => _wrapText(text, maxChars: maxChars);

    // ========== HEADER SECTION ==========
    // Main header background (forest green)
    setColor(0.11, 0.37, 0.13);
    drawRect(0, pageHeight - 85, pageWidth, 85);
    
    // Gold accent strip
    setColor(0.76, 0.60, 0.20);
    drawRect(0, pageHeight - 88, pageWidth, 3);

    // Header content
    drawText('MAIZE GUARD', marginLeft, pageHeight - 35, 24, color: 'white');
    drawText('Field Disease Analysis Report', marginLeft, pageHeight - 52, 11, color: 'white');
    drawText('Offline AI-Powered Crop Intelligence', marginLeft, pageHeight - 66, 9, color: 'white');
    
    // Date box (right side)
    setColor(0.08, 0.28, 0.10);
    drawRect(pageWidth - 140, pageHeight - 75, 100, 50);
    drawText(DateTimeFormatter.formatDate(input.timestamp), pageWidth - 130, pageHeight - 45, 9, color: 'white');
    drawText(DateTimeFormatter.formatTime(input.timestamp), pageWidth - 130, pageHeight - 58, 9, color: 'white');

    cursorY = pageHeight - 105;

    // ========== DIAGNOSIS RESULT CARD ==========
    final diagnosisCardHeight = 130.0;
    setColor(0.97, 0.97, 0.95);
    drawRect(marginLeft, cursorY - diagnosisCardHeight, contentWidth, diagnosisCardHeight);
    setStrokeColor(0.85, 0.85, 0.85);
    content.writeln('1 w');
    drawRect(marginLeft, cursorY - diagnosisCardHeight, contentWidth, diagnosisCardHeight, fill: false, stroke: true);

    // Section title with green accent bar
    setColor(0.11, 0.37, 0.13);
    drawRect(marginLeft, cursorY - 25, 4, 20);
    drawText('DIAGNOSIS RESULT', marginLeft + 12, cursorY - 20, 11, color: 'green');

    // Disease name - large and prominent
    final diseaseName = LabelFormatter.toDisplayLabel(input.predictedLabel);
    drawText(diseaseName, marginLeft + 12, cursorY - 50, 20, color: 'dark');

    // Confidence indicator
    final confidencePercent = (input.confidence * 100).toStringAsFixed(1);
    drawText('Confidence Level', marginLeft + 12, cursorY - 75, 9, color: 'gray');
    
    // Confidence bar background
    setColor(0.88, 0.88, 0.88);
    drawRect(marginLeft + 12, cursorY - 95, 200, 12);
    
    // Confidence bar fill (green gradient effect)
    final barWidth = 200.0 * input.confidence;
    if (input.confidence >= 0.7) {
      setColor(0.20, 0.60, 0.25); // Green for high confidence
    } else if (input.confidence >= 0.4) {
      setColor(0.76, 0.60, 0.20); // Gold for medium
    } else {
      setColor(0.80, 0.35, 0.25); // Red for low
    }
    drawRect(marginLeft + 12, cursorY - 95, barWidth, 12);
    drawText('$confidencePercent%', marginLeft + 220, cursorY - 93, 10, color: 'dark');

    // Quality score on the right
    final qualityPercent = (input.qualityScore * 100).toStringAsFixed(0);
    drawText('Image Quality: $qualityPercent%', marginLeft + 320, cursorY - 75, 9, color: 'gray');

    // Image placement (right side of diagnosis card)
    double imgDrawWidth = 100.0;
    double imgDrawHeight = 100.0;
    if (imageWidth > 0 && imageHeight > 0) {
      final aspect = imageWidth / imageHeight;
      if (aspect > 1) {
        imgDrawHeight = imgDrawWidth / aspect;
      } else {
        imgDrawWidth = imgDrawHeight * aspect;
      }
    }
    final imgX = pageWidth - marginRight - imgDrawWidth - 10;
    final imgY = cursorY - diagnosisCardHeight + 15;

    // Image border
    setColor(0.85, 0.85, 0.85);
    drawRect(imgX - 3, imgY - 3, imgDrawWidth + 6, imgDrawHeight + 6);

    if (jpgBytes != null) {
      content
        ..writeln('q')
        ..writeln('${imgDrawWidth.toStringAsFixed(1)} 0 0 ${imgDrawHeight.toStringAsFixed(1)} ${imgX.toStringAsFixed(1)} ${imgY.toStringAsFixed(1)} cm')
        ..writeln('/Im1 Do')
        ..writeln('Q');
    }

    cursorY -= diagnosisCardHeight + 15;

    // ========== SUMMARY SECTION ==========
    setColor(0.11, 0.37, 0.13);
    drawRect(marginLeft, cursorY - 20, 4, 15);
    drawText('SUMMARY', marginLeft + 12, cursorY - 16, 10, color: 'green');
    cursorY -= 30;

    final summaryLines = wrapText(input.diseaseSummary, 90);
    for (final line in summaryLines) {
      drawText(line, marginLeft + 12, cursorY, 9, color: 'dark');
      cursorY -= 13;
    }
    cursorY -= 10;

    // ========== PROBABILITY RANKINGS ==========
    setColor(0.97, 0.97, 0.95);
    final probCardHeight = 90.0;
    drawRect(marginLeft, cursorY - probCardHeight, contentWidth / 2 - 8, probCardHeight);
    
    setColor(0.11, 0.37, 0.13);
    drawRect(marginLeft, cursorY - 20, 4, 15);
    drawText('PROBABILITY RANKINGS', marginLeft + 12, cursorY - 16, 10, color: 'green');
    
    var probY = cursorY - 35;
    for (final item in sorted.take(4)) {
      final label = LabelFormatter.toDisplayLabel(item.key);
      final prob = (item.value * 100).toStringAsFixed(1);
      drawText('$label:', marginLeft + 12, probY, 8, color: 'dark');
      drawText('$prob%', marginLeft + 150, probY, 8, color: 'gray');
      probY -= 14;
    }

    // ========== FARMER PROFILE (right column) ==========
    final profileX = marginLeft + contentWidth / 2 + 8;
    setColor(0.97, 0.97, 0.95);
    drawRect(profileX, cursorY - probCardHeight, contentWidth / 2 - 8, probCardHeight);
    
    setColor(0.76, 0.60, 0.20);
    drawRect(profileX, cursorY - 20, 4, 15);
    drawText('REPORT DETAILS', profileX + 12, cursorY - 16, 10, color: 'gold');
    
    var profileY = cursorY - 35;
    if ((input.farmerName ?? '').trim().isNotEmpty) {
      drawText('Farmer: ${input.farmerName}', profileX + 12, profileY, 8, color: 'dark');
      profileY -= 14;
    }
    if ((input.farmerLocation ?? '').trim().isNotEmpty) {
      drawText('Location: ${input.farmerLocation}', profileX + 12, profileY, 8, color: 'dark');
      profileY -= 14;
    }
    drawText('Model: ${input.modelVersion}', profileX + 12, profileY, 8, color: 'gray');
    profileY -= 14;
    drawText('Catalog: ${input.catalogVersion}', profileX + 12, profileY, 8, color: 'gray');

    cursorY -= probCardHeight + 15;

    // ========== GUIDANCE SECTION ==========
    setColor(0.11, 0.37, 0.13);
    drawRect(marginLeft, cursorY - 20, 4, 15);
    drawText('RECOMMENDED ACTIONS', marginLeft + 12, cursorY - 16, 10, color: 'green');
    cursorY -= 35;

    var guideNum = 1;
    for (final guide in input.guidance.take(6)) {
      final lines = wrapText('$guideNum. $guide', 90);
      for (final line in lines) {
        if (cursorY < 100) break; // Don't overflow into footer
        drawText(line, marginLeft + 12, cursorY, 9, color: 'dark');
        cursorY -= 13;
      }
      cursorY -= 4;
      guideNum++;
    }

    // ========== FOOTER ==========
    // Footer background
    setColor(0.95, 0.95, 0.93);
    drawRect(0, 0, pageWidth, 60);
    
    // Footer accent line
    setColor(0.11, 0.37, 0.13);
    drawRect(0, 60, pageWidth, 2);

    // Disclaimer
    drawText('DISCLAIMER', marginLeft, 42, 8, color: 'green');
    drawText('This report is generated by Maize Guard AI for decision support purposes only.', marginLeft, 28, 7, color: 'gray');
    drawText('It does not replace professional agronomic advice or laboratory confirmation. Consult a specialist for critical decisions.', marginLeft, 18, 7, color: 'gray');
    
    // Page info
    drawText('Generated by Maize Guard', pageWidth - 150, 42, 7, color: 'lightgray');
    drawText('Page 1 of 1', pageWidth - 80, 28, 7, color: 'lightgray');

    // ========== BUILD PDF STRUCTURE ==========
    final pageObjectId = 3;
    final fontObjectId = 4;
    final imageObjectId = 5;
    final contentObjectId = 6;

    final pageResources = StringBuffer()
      ..write('/Font << /F1 $fontObjectId 0 R >> ');
    if (jpgBytes != null) {
      pageResources.write('/XObject << /Im1 $imageObjectId 0 R >> ');
    }

    final objects = <_PdfObject>[
      _PdfObject(1, _asciiBytes('<< /Type /Catalog /Pages 2 0 R >>')),
      _PdfObject(2, _asciiBytes('<< /Type /Pages /Kids [$pageObjectId 0 R] /Count 1 >>')),
      _PdfObject(
        pageObjectId,
        _asciiBytes(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << ${pageResources.toString()}>> /Contents $contentObjectId 0 R >>',
        ),
      ),
      _PdfObject(fontObjectId, _asciiBytes('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')),
      if (jpgBytes != null)
        _PdfObject(
          imageObjectId,
          _binaryObject(
            '<< /Type /XObject /Subtype /Image /Width $imageWidth /Height $imageHeight /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpgBytes.length} >>',
            jpgBytes,
          ),
        ),
      _PdfObject(
        contentObjectId,
        _asciiBytes(
          '<< /Length ${ascii.encode(content.toString()).length} >>\nstream\n${content.toString()}endstream',
        ),
      ),
    ];

    final builder = BytesBuilder();
    builder.add(_asciiBytes('%PDF-1.4\n'));
    final offsets = <int>[0];

    for (final object in objects) {
      offsets.add(builder.length);
      builder.add(_asciiBytes('${object.id} 0 obj\n'));
      builder.add(object.bytes);
      builder.add(_asciiBytes('\nendobj\n'));
    }

    final xrefOffset = builder.length;
    builder.add(_asciiBytes('xref\n0 ${objects.length + 1}\n'));
    builder.add(_asciiBytes('0000000000 65535 f \n'));
    for (var i = 1; i < offsets.length; i++) {
      builder.add(_asciiBytes('${offsets[i].toString().padLeft(10, '0')} 00000 n \n'));
    }
    builder.add(
      _asciiBytes(
        'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF',
      ),
    );

    return builder.toBytes();
  }

  static Uint8List _asciiBytes(String value) =>
      Uint8List.fromList(ascii.encode(value));

  static Uint8List _binaryObject(String header, Uint8List bytes) {
    final builder = BytesBuilder();
    builder.add(_asciiBytes('$header\nstream\n'));
    builder.add(bytes);
    builder.add(_asciiBytes('\nendstream'));
    return builder.toBytes();
  }

  static String _escapePdfText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ');
  }

  static List<String> _wrapText(String text, {required int maxChars}) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    final current = StringBuffer();

    for (final word in words) {
      if (word.isEmpty) continue;
      final tentative = current.isEmpty ? word : '${current.toString()} $word';
      if (tentative.length <= maxChars) {
        current
          ..clear()
          ..write(tentative);
      } else {
        if (current.isNotEmpty) {
          lines.add(current.toString());
        }
        current
          ..clear()
          ..write(word);
      }
    }

    if (current.isNotEmpty) {
      lines.add(current.toString());
    }
    return lines;
  }

  static Future<Directory> _resolveBaseDirectory() async {
    // Try to use Downloads folder for public accessibility
    if (Platform.isAndroid) {
      // Android Downloads folder - publicly accessible
      final downloadsDir = Directory('/storage/emulated/0/Download/MaizeGuard');
      try {
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        // Test write access
        final testFile = File('${downloadsDir.path}/.test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
        return downloadsDir;
      } catch (_) {
        // Fall back to external storage if Downloads not accessible
      }
    }
    
    // Fallback for iOS or if Android Downloads fails
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
    return getApplicationDocumentsDirectory();
  }
}

class _PdfObject {
  const _PdfObject(this.id, this.bytes);

  final int id;
  final Uint8List bytes;
}
