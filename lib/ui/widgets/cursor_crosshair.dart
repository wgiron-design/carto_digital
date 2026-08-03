import 'package:flutter/material.dart';

/// Cursor de precisión tipo "mira" (crosshair) para la digitación.
///
/// Se posiciona siempre en el centro del mapa. El usuario mueve el mapa
/// para posicionar el crosshair en el lugar donde quiere agregar un nodo.
class CursorCrosshair extends StatelessWidget {
  const CursorCrosshair({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: CustomPaint(
            painter: _CrosshairPainter(),
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // ── Sombra exterior (para visibilidad sobre fondos claros) ──
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Círculo sombra
    canvas.drawCircle(center, radius, shadowPaint);

    // Cruz sombra
    // Línea horizontal
    canvas.drawLine(
      Offset(center.dx - radius - 4, center.dy),
      Offset(center.dx - 6, center.dy),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + radius + 4, center.dy),
      shadowPaint,
    );
    // Línea vertical
    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 4),
      Offset(center.dx, center.dy - 6),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx, center.dy + radius + 4),
      shadowPaint,
    );

    // ── Trazo principal (blanco brillante) ──
    final mainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Círculo principal
    canvas.drawCircle(center, radius, mainPaint);

    // Cruz principal (con hueco en el centro para precisión)
    // Línea horizontal
    canvas.drawLine(
      Offset(center.dx - radius - 4, center.dy),
      Offset(center.dx - 6, center.dy),
      mainPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + radius + 4, center.dy),
      mainPaint,
    );
    // Línea vertical
    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 4),
      Offset(center.dx, center.dy - 6),
      mainPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx, center.dy + radius + 4),
      mainPaint,
    );

    // ── Punto central diminuto (rojo) para máxima precisión ──
    final dotPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
