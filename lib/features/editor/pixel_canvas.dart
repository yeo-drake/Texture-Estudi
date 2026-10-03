import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class PixelCanvas extends StatelessWidget {
  final img.Image image;
  final void Function(int x, int y) onPaintAt;

  const PixelCanvas({
    super.key,
    required this.image,
    required this.onPaintAt,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = min(
          constraints.maxWidth / image.width,
          constraints.maxHeight / image.height,
        );
        final w = image.width * scale;
        final h = image.height * scale;

        void handle(Offset pos) {
          final x = (pos.dx / scale).floor();
          final y = (pos.dy / scale).floor();
          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            onPaintAt(x, y);
          }
        }

        return Center(
          child: GestureDetector(
            onTapDown: (d) => handle(d.localPosition),
            onPanStart: (d) => handle(d.localPosition),
            onPanUpdate: (d) => handle(d.localPosition),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
              ),
              child: SizedBox(
                width: w,
                height: h,
                child: CustomPaint(painter: _PixelPainter(image)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PixelPainter extends CustomPainter {
  final img.Image image;
  _PixelPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final pxW = size.width / image.width;
    final pxH = size.height / image.height;
    final paint = Paint();

    // Fondo a cuadros para ver transparencia
    final bg = Paint();
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final even = (x + y) % 2 == 0;
        bg.color = even ? const Color(0xFF2A2A2A) : const Color(0xFF3A3A3A);
        canvas.drawRect(
          Rect.fromLTWH(x * pxW, y * pxH, pxW, pxH),
          bg,
        );
      }
    }

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final a = p.a.toInt();
        if (a == 0) continue;
        paint.color = Color.fromARGB(
          a,
          p.r.toInt(),
          p.g.toInt(),
          p.b.toInt(),
        );
        canvas.drawRect(
          Rect.fromLTWH(x * pxW, y * pxH, pxW, pxH),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) => true;
}