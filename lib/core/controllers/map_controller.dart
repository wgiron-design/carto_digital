import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/imagen_calibrada.dart';

/// Estado y lógica del visor de mapa.
/// Gestiona: imagen de fondo calibrada, zoom, centro del mapa.
class MapController extends ChangeNotifier {
  // ── Estado de imagen de fondo ─────────────────────────────────────────────

  ImagenCalibrada? _imagenFondo;
  ImagenCalibrada? get imagenFondo => _imagenFondo;
  bool get tieneImagenFondo => _imagenFondo != null;

  // ── Estado de vista del mapa ──────────────────────────────────────────────

  /// Centro actual del mapa
  LatLng _centro = const LatLng(14.5, -90.5); // Guatemala por defecto
  LatLng get centro => _centro;

  /// Zoom actual del mapa
  double _zoom = 10.0;
  double get zoom => _zoom;

  // ── Capas visibles ────────────────────────────────────────────────────────

  bool _mostrarImagenFondo = true;
  bool get mostrarImagenFondo => _mostrarImagenFondo;

  bool _mostrarMapaBase = true;
  bool get mostrarMapaBase => _mostrarMapaBase;

  // ── Acciones ──────────────────────────────────────────────────────────────

  /// Establece la imagen de fondo calibrada y centra el mapa en ella
  void establecerImagenFondo(ImagenCalibrada imagen) {
    _imagenFondo = imagen;
    // Centrar el mapa en la imagen cargada
    _centro = imagen.centro;
    // Calcular zoom apropiado basado en el span de la imagen
    _zoom = _calcularZoomInicial(imagen);
    notifyListeners();
  }

  /// Actualiza solo los parámetros de calibración de la imagen existente
  void actualizarCalibracion(ImagenCalibrada nuevaImagen) {
    _imagenFondo = nuevaImagen;
    notifyListeners();
  }

  /// Elimina la imagen de fondo
  void quitarImagenFondo() {
    _imagenFondo = null;
    notifyListeners();
  }

  /// Alterna la visibilidad de la imagen de fondo
  void toggleImagenFondo() {
    _mostrarImagenFondo = !_mostrarImagenFondo;
    notifyListeners();
  }

  /// Alterna la visibilidad del mapa base online
  void toggleMapaBase() {
    _mostrarMapaBase = !_mostrarMapaBase;
    notifyListeners();
  }

  /// Actualiza la opacidad de la imagen de fondo (0.0 a 1.0)
  void setOpacidadImagen(double opacidad) {
    if (_imagenFondo != null) {
      _imagenFondo = _imagenFondo!.copyWith(opacidad: opacidad);
      notifyListeners();
    }
  }

  /// Actualiza el centro del mapa (llamado por el mapa al hacer pan)
  void actualizarCentro(LatLng nuevoCentro) {
    _centro = nuevoCentro;
    // No notifica para evitar rebuilds en cada frame de animación
  }

  /// Actualiza el zoom (llamado por el mapa al hacer pinch-zoom)
  void actualizarZoom(double nuevoZoom) {
    _zoom = nuevoZoom;
    // No notifica para evitar rebuilds en cada frame de animación
  }

  // ── Utilidades privadas ───────────────────────────────────────────────────

  /// Calcula el zoom inicial apropiado para que la imagen llene ~70% de la pantalla
  double _calcularZoomInicial(ImagenCalibrada imagen) {
    final span = imagen.spanLat > imagen.spanLng ? imagen.spanLat : imagen.spanLng;
    // Heurística: ajustar zoom según el span en grados
    if (span > 5.0) return 8.0;
    if (span > 1.0) return 10.0;
    if (span > 0.1) return 13.0;
    if (span > 0.01) return 15.0;
    if (span > 0.001) return 17.0;
    return 18.0;
  }
}
