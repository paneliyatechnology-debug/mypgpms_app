import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';

/// Interactive touch signature drawing pad.
class SignaturePadWidget extends StatefulWidget {
  final ValueChanged<bool>? onSignatureChanged;

  const SignaturePadWidget({super.key, this.onSignatureChanged});

  @override
  State<SignaturePadWidget> createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _strokes = [];

  void clear() {
    setState(() {
      _strokes.clear();
    });
    widget.onSignatureChanged?.call(false);
  }

  Future<String?> exportSignatureToFile() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 160));
      final paint = Paint()
        ..color = const Color(0xFF146A4F)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (_strokes.isEmpty) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'Digital Signature Approved',
            style: TextStyle(
              color: Color(0xFF146A4F),
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, const Offset(30, 60));
      } else {
        for (final stroke in _strokes) {
          if (stroke.length < 2) continue;
          final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
          for (int i = 1; i < stroke.length; i++) {
            path.lineTo(stroke[i].dx, stroke[i].dy);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 160);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Stack(
        children: [
          // Drawing Canvas
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _strokes.add([details.localPosition]);
              });
              widget.onSignatureChanged?.call(true);
            },
            onPanUpdate: (details) {
              setState(() {
                if (_strokes.isNotEmpty) {
                  _strokes.last.add(details.localPosition);
                }
              });
            },
            child: CustomPaint(
              painter: _SignaturePainter(strokes: _strokes),
              size: Size.infinite,
            ),
          ),

          // Default placeholder signature if untouched
          if (_strokes.isEmpty)
            Center(
              child: Text(
                'Draw signature here',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 13.0,
                ),
              ),
            ),

          // Clear Button
          Positioned(
            right: 16.0,
            bottom: 12.0,
            child: GestureDetector(
              onTap: clear,
              child: Text(
                'Clear',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF153327)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
