import 'package:latlong2/latlong.dart';

/// Tipo de elemento al que se hace snap.
enum SnapType {
  /// Snap exacto a un vértice existente → se dibuja un cuadrito rosa.
  vertex,

  /// Snap al punto más cercano sobre un segmento → se dibuja un triángulo rosa.
  segment,
}

/// Resultado de un cálculo de snap.
///
/// Contiene la coordenada destino del snap, el tipo de elemento
/// al que se está snapeando y la distancia en píxeles al cursor.
class SnapResult {
  /// Coordenada exacta a la que se hará snap al agregar el vértice.
  final LatLng snapPoint;

  /// Tipo de snap detectado (vértice o segmento).
  final SnapType type;

  /// Distancia en píxeles entre el crosshair y el punto de snap.
  /// Siempre ≤ [DigitalizacionController.snapRadiusPx].
  final double distancePx;

  const SnapResult({
    required this.snapPoint,
    required this.type,
    required this.distancePx,
  });
}
