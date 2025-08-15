import 'package:flutter/material.dart';
import '../models/mark.dart';

/// วาดกระดาน NxN และเครื่องหมาย 'O' / 'X'
class BoardPainter extends CustomPainter {
  final List<Mark> marks;
  final double markSize;
  final int gridSize;

  BoardPainter({
    required this.marks,
    required this.markSize,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cellWidth = size.width / gridSize;
    final double cellHeight = size.height / gridSize;

    // วาดเส้นตั้ง
    for (int i = 1; i < gridSize; i++) {
      final double x = cellWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // วาดเส้นนอน
    for (int i = 1; i < gridSize; i++) {
      final double y = cellHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Paint oPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final Paint xPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    for (final Mark mark in marks) {
      if (mark.type == 'O') {
        canvas.drawCircle(mark.position, markSize / 2, oPaint);
      } else if (mark.type == 'X') {
        final double halfSize = markSize / 2;
        canvas.drawLine(
          mark.position + Offset(-halfSize, -halfSize),
          mark.position + Offset(halfSize, halfSize),
          xPaint,
        );
        canvas.drawLine(
          mark.position + Offset(-halfSize, halfSize),
          mark.position + Offset(halfSize, -halfSize),
          xPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.marks != marks ||
        oldDelegate.markSize != markSize ||
        oldDelegate.gridSize != gridSize;
  }
}
