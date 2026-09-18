import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class AppQrWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const AppQrWidget({
    super.key,
    required this.data,
    this.size = 140,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
        ),
      );
    }

    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);

      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: CustomPaint(
          size: Size(size, size),
          painter: _QrPainter(qrImage: qrImage, color: color),
        ),
      );
    } catch (e) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
        ),
      );
    }
  }
}

class _QrPainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;

  _QrPainter({required this.qrImage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    if (moduleCount == 0) return;

    final pixelSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.qrImage != qrImage;
}
