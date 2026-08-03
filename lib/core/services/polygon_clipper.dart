import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Servicio de recorte de polígonos para el auto-ensamblado topológico.
///
/// Implementa el algoritmo de **Sutherland–Hodgman** para calcular la diferencia
/// geométrica entre un polígono nuevo y una colección de polígonos existentes.
///
/// Las coordenadas LatLng se tratan como planas (proyección equirrectangular
/// local), lo cual es suficientemente preciso para áreas de trabajo < 10 km².
class PolygonClipper {
  PolygonClipper._(); // Clase utilitaria estática

  // ─────────────────────────────────────────────────────────────────────────
  // API PÚBLICA
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula [newPoly] menos cualquier área solapada con [existingPolys].
  ///
  /// Si no hay solapamiento con ningún polígono existente, retorna [newPoly]
  /// sin modificaciones. Si el resultado tiene < 3 vértices (el nuevo queda
  /// completamente dentro de uno existente), retorna una lista vacía.
  static List<LatLng> differencePolygon(
    List<LatLng> newPoly,
    List<List<LatLng>> existingPolys,
  ) {
    List<LatLng> result = List.from(newPoly);

    for (final existing in existingPolys) {
      if (result.length < 3) break; // Ya no queda polígono

      // Filtro rápido de bounding box antes del clip costoso
      if (!_boundingBoxOverlap(result, existing)) continue;

      // Verificar si hay solapamiento real antes de recortar
      if (!_polygonsOverlap(result, existing)) continue;

      // Calcular la diferencia: result = result - existing
      final clipped = _difference(result, existing);
      if (clipped != null && clipped.length >= 3) {
        result = clipped;
      } else if (clipped == null) {
        // El polígono nuevo está completamente dentro del existente
        return [];
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIFERENCIA GEOMÉTRICA
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula [subject] - [clipper] usando el complemento de Sutherland–Hodgman.
  ///
  /// Para la diferencia, invertimos el winding del clipper antes de aplicar
  /// el algoritmo de intersección estándar.
  ///
  /// Retorna null si subject está completamente dentro de clipper.
  static List<LatLng>? _difference(
    List<LatLng> subject,
    List<LatLng> clipper,
  ) {
    // Verificar si subject está completamente dentro de clipper
    final allInside = subject.every((v) => _pointInPolygon(v, clipper));
    if (allInside) return null;

    // Calcular la intersección subject ∩ clipper
    final intersection = _sutherlandHodgman(subject, clipper);
    if (intersection.isEmpty) {
      // No hay intersección real → retornar subject sin cambios
      return subject;
    }

    // Para la diferencia necesitamos recortar subject contra el exterior del clipper.
    // Esto se logra invirtiendo la orientación del clipper (complement clipping).
    //
    // Estrategia práctica: tomamos los vértices del subject que están FUERA
    // del clipper y los unimos con los puntos de intersección de los bordes.
    return _computeDifference(subject, clipper);
  }

  /// Calcula la región de [subject] que está **fuera** de [clipper].
  ///
  /// Recorre las aristas de subject e incluye:
  /// - Vértices que están fuera del clipper
  /// - Puntos de intersección donde una arista entra/sale del clipper
  static List<LatLng> _computeDifference(
    List<LatLng> subject,
    List<LatLng> clipper,
  ) {
    final result = <LatLng>[];
    final n = subject.length;

    for (int i = 0; i < n; i++) {
      final current = subject[i];
      final next = subject[(i + 1) % n];

      final currentInside = _pointInPolygon(current, clipper);
      final nextInside = _pointInPolygon(next, clipper);

      if (!currentInside) {
        result.add(current);
      }

      if (currentInside != nextInside) {
        // La arista cruza el borde del clipper → encontrar el punto exacto
        final intersection = _findEdgeIntersection(current, next, clipper);
        if (intersection != null) {
          result.add(intersection);
        }
      }
    }

    // Eliminar duplicados consecutivos muy cercanos
    return _removeDuplicates(result);
  }

  /// Encuentra el punto donde la arista [p1]→[p2] intersecta el borde de [polygon].
  static LatLng? _findEdgeIntersection(
    LatLng p1,
    LatLng p2,
    List<LatLng> polygon,
  ) {
    LatLng? closest;
    double minDist = double.infinity;

    final n = polygon.length;
    for (int i = 0; i < n; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % n];

      final intersection = _segmentIntersection(p1, p2, a, b);
      if (intersection != null) {
        final d = _dist2(p1, intersection);
        if (d < minDist) {
          minDist = d;
          closest = intersection;
        }
      }
    }
    return closest;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUTHERLAND–HODGMAN (Intersección)
  // ─────────────────────────────────────────────────────────────────────────

  /// Algoritmo de Sutherland–Hodgman para calcular [subject] ∩ [clipper].
  ///
  /// [clipper] debe estar en orden antihorario (o el resultado es correcto
  /// para el winding estándar de LatLng).
  static List<LatLng> _sutherlandHodgman(
    List<LatLng> subject,
    List<LatLng> clipper,
  ) {
    List<LatLng> output = List.from(subject);
    if (output.isEmpty) return [];

    final n = clipper.length;
    for (int i = 0; i < n; i++) {
      if (output.isEmpty) return [];

      final edgeStart = clipper[i];
      final edgeEnd = clipper[(i + 1) % n];

      final input = List<LatLng>.from(output);
      output.clear();

      for (int j = 0; j < input.length; j++) {
        final current = input[j];
        final previous = input[(j + input.length - 1) % input.length];

        if (_isInsideEdge(current, edgeStart, edgeEnd)) {
          if (!_isInsideEdge(previous, edgeStart, edgeEnd)) {
            final intersection = _segmentIntersection(
                previous, current, edgeStart, edgeEnd);
            if (intersection != null) output.add(intersection);
          }
          output.add(current);
        } else if (_isInsideEdge(previous, edgeStart, edgeEnd)) {
          final intersection = _segmentIntersection(
              previous, current, edgeStart, edgeEnd);
          if (intersection != null) output.add(intersection);
        }
      }
    }

    return _removeDuplicates(output);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILIDADES GEOMÉTRICAS
  // ─────────────────────────────────────────────────────────────────────────

  /// Retorna true si [p] está en el semiplano "dentro" de la arista [a]→[b]
  /// (usando el determinante del cross product del plano 2D).
  static bool _isInsideEdge(LatLng p, LatLng a, LatLng b) {
    return _cross(a, b, p) >= 0;
  }

  /// Cross product 2D (z-component) del vector (b-a) × (p-a).
  static double _cross(LatLng a, LatLng b, LatLng p) {
    return (b.longitude - a.longitude) * (p.latitude - a.latitude) -
        (b.latitude - a.latitude) * (p.longitude - a.longitude);
  }

  /// Calcula la intersección de los segmentos [p1]→[p2] y [p3]→[p4].
  /// Retorna null si son paralelos o no se intersectan dentro del segmento.
  static LatLng? _segmentIntersection(
    LatLng p1,
    LatLng p2,
    LatLng p3,
    LatLng p4,
  ) {
    final d1x = p2.longitude - p1.longitude;
    final d1y = p2.latitude - p1.latitude;
    final d2x = p4.longitude - p3.longitude;
    final d2y = p4.latitude - p3.latitude;

    final denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-12) return null; // Paralelos

    final t = ((p3.longitude - p1.longitude) * d2y -
            (p3.latitude - p1.latitude) * d2x) /
        denom;
    final u = ((p3.longitude - p1.longitude) * d1y -
            (p3.latitude - p1.latitude) * d1x) /
        denom;

    if (t < -1e-9 || t > 1 + 1e-9 || u < -1e-9 || u > 1 + 1e-9) return null;

    return LatLng(
      p1.latitude + t * d1y,
      p1.longitude + t * d1x,
    );
  }

  /// Ray-casting algorithm para determinar si [point] está dentro de [polygon].
  static bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int crossings = 0;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      if ((yi > point.latitude) != (yj > point.latitude)) {
        final xIntersect =
            (xj - xi) * (point.latitude - yi) / (yj - yi) + xi;
        if (point.longitude < xIntersect) crossings++;
      }
    }
    return crossings % 2 == 1;
  }

  /// Verificación rápida de solapamiento de bounding boxes.
  static bool _boundingBoxOverlap(
      List<LatLng> a, List<LatLng> b) {
    double aMinLat = double.infinity,
        aMaxLat = -double.infinity,
        aMinLng = double.infinity,
        aMaxLng = -double.infinity;
    double bMinLat = double.infinity,
        bMaxLat = -double.infinity,
        bMinLng = double.infinity,
        bMaxLng = -double.infinity;

    for (final v in a) {
      if (v.latitude < aMinLat) aMinLat = v.latitude;
      if (v.latitude > aMaxLat) aMaxLat = v.latitude;
      if (v.longitude < aMinLng) aMinLng = v.longitude;
      if (v.longitude > aMaxLng) aMaxLng = v.longitude;
    }
    for (final v in b) {
      if (v.latitude < bMinLat) bMinLat = v.latitude;
      if (v.latitude > bMaxLat) bMaxLat = v.latitude;
      if (v.longitude < bMinLng) bMinLng = v.longitude;
      if (v.longitude > bMaxLng) bMaxLng = v.longitude;
    }

    return aMinLat <= bMaxLat &&
        aMaxLat >= bMinLat &&
        aMinLng <= bMaxLng &&
        aMaxLng >= bMinLng;
  }

  /// Verifica si dos polígonos tienen algún solapamiento real
  /// (no solo que sus bounding boxes coincidan).
  static bool _polygonsOverlap(List<LatLng> a, List<LatLng> b) {
    // Si algún vértice de a está dentro de b o viceversa → solapamiento
    for (final v in a) {
      if (_pointInPolygon(v, b)) return true;
    }
    for (final v in b) {
      if (_pointInPolygon(v, a)) return true;
    }
    // Verificar si alguna arista se intersecta
    final na = a.length;
    final nb = b.length;
    for (int i = 0; i < na; i++) {
      for (int j = 0; j < nb; j++) {
        if (_segmentIntersection(
              a[i],
              a[(i + 1) % na],
              b[j],
              b[(j + 1) % nb],
            ) !=
            null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Distancia cuadrada entre dos puntos (para comparación rápida).
  static double _dist2(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng;
  }

  /// Elimina vértices duplicados consecutivos (threshold: 1e-9 grados ≈ 0.1mm).
  static List<LatLng> _removeDuplicates(List<LatLng> pts) {
    if (pts.length < 2) return pts;
    final result = <LatLng>[pts[0]];
    for (int i = 1; i < pts.length; i++) {
      if (_dist2(pts[i], result.last) > 1e-18) {
        result.add(pts[i]);
      }
    }
    // Eliminar si el último es igual al primero
    if (result.length > 1 && _dist2(result.last, result.first) < 1e-18) {
      result.removeLast();
    }
    return result;
  }
}
