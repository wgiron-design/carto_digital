import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/models/snap_result.dart';

/// Widget que dibuja el indicador visual de snap encima del mapa.
///
/// - **Vértice**: cuadrito rosa con borde blanco (14×14 px).
/// - **Segmento**: triángulo rosa con borde blanco, punta hacia arriba (16 px).
///
/// Se posiciona en pantalla usando las coordenadas pixel del punto de snap.
class SnapIndicator extends StatefulWidget {
  /// Posición en pantalla (píxeles) donde centrar el indicador.
  final Offset screenPosition;

  /// Tipo de snap a representar.
  final SnapType snapType;

  const SnapIndicator({
    super.key,
    required this.screenPosition,
    required this.snapType,
  });

  @override
  State<SnapIndicator> createState() => _SnapIndicatorState();
}

class _SnapIndicatorState extends State<SnapIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 18.0;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Positioned(
          left: widget.screenPosition.dx - size / 2,
          top: widget.screenPosition.dy - size / 2,
          child: Opacity(
            opacity: _pulseAnim.value,
            child: CustomPaint(
              size: const Size(size, size),
              painter: widget.snapType == SnapType.vertex
                  ? _SquarePainter()
                  : _TrianglePainter(),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuadrito rosa — Snap a vértice
// ─────────────────────────────────────────────────────────────────────────────

class _SquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sombra exterior para contraste sobre fondos oscuros/claros
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Relleno rosa
    final fillPaint = Paint()
      ..color = const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.fill;

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - 2,
      height: size.height - 2,
    );

    // Sombra
    canvas.drawRect(rect.translate(1, 1), shadowPaint..color = Colors.black.withValues(alpha: 0.3));
    // Relleno
    canvas.drawRect(rect, fillPaint);
    // Borde
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Triángulo rosa — Snap a segmento
// ─────────────────────────────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    // Triángulo equilátero, punta hacia arriba
    final double cx = size.width / 2;
    final double h = size.height;
    final double w = size.width;

    // Altura del triángulo equilátero inscrito
    final double triH = w * math.sqrt(3) / 2;
    final double baseY = (h + triH) / 2;
    final double topY = baseY - triH;

    final path = Path()
      ..moveTo(cx, topY)                 // Punta superior
      ..lineTo(cx + w / 2, baseY)        // Vértice inferior derecho
      ..lineTo(cx - w / 2, baseY)        // Vértice inferior izquierdo
      ..close();

    // Sombra
    canvas.save();
    canvas.translate(1, 1);
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill);
    canvas.restore();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
