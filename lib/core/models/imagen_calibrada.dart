import 'package:latlong2/latlong.dart';

/// Modelo que representa una imagen de fondo calibrada geográficamente.
/// La calibración define el bounding box de la imagen en coordenadas WGS84.
///
/// La imagen se proyecta sobre el mapa como un "Image Overlay" usando
/// flutter_map's OverlayImageLayer. La imagen se estira para llenar el
/// bounding box definido por los cuatro límites geográficos.
///
/// Sistema de coordenadas: WGS84 (Lat/Lng nativas), sin conversión UTM.
class ImagenCalibrada {
  /// Ruta local del archivo de imagen (JPG/PNG) en el dispositivo
  final String rutaArchivo;

  /// Nombre visible de la imagen para la UI
  final String nombre;

  // ── Límites geográficos del bounding box (WGS84) ──────────────────────────

  /// Latitud del borde NORTE (máximo Y) — ejemplo: 15.5432
  final double norte;

  /// Latitud del borde SUR (mínimo Y) — ejemplo: 15.4123
  final double sur;

  /// Longitud del borde ESTE (máximo X) — ejemplo: -88.1234
  final double este;

  /// Longitud del borde OESTE (mínimo X) — ejemplo: -88.3456
  final double oeste;

  /// Opacidad de la imagen sobre el mapa (0.0 = invisible, 1.0 = opaca)
  final double opacidad;

  /// Indica si la capa de imagen está visible
  final bool visible;

  const ImagenCalibrada({
    required this.rutaArchivo,
    required this.nombre,
    required this.norte,
    required this.sur,
    required this.este,
    required this.oeste,
    this.opacidad = 0.85,
    this.visible = true,
  });

  /// Esquina noreste del bounding box
  LatLng get esquinaNE => LatLng(norte, este);

  /// Esquina suroeste del bounding box
  LatLng get esquinaSO => LatLng(sur, oeste);

  /// Centro geográfico de la imagen (para centrar el mapa)
  LatLng get centro => LatLng(
        (norte + sur) / 2.0,
        (este + oeste) / 2.0,
      );

  /// Span en grados (para calcular el zoom inicial apropiado)
  double get spanLat => (norte - sur).abs();
  double get spanLng => (este - oeste).abs();

  /// Valida que el bounding box tenga sentido geográfico
  bool get esValida {
    if (rutaArchivo.isEmpty) return false;
    if (norte <= sur) return false;       // Norte debe ser mayor que Sur
    if (este == oeste) return false;       // Este y Oeste no pueden coincidir
    if (norte > 90 || sur < -90) return false;
    if (este > 180 || oeste < -180) return false;
    return true;
  }

  /// Serialización para almacenamiento en JSON
  Map<String, dynamic> toJson() => {
        'rutaArchivo': rutaArchivo,
        'nombre': nombre,
        'norte': norte,
        'sur': sur,
        'este': este,
        'oeste': oeste,
        'opacidad': opacidad,
        'visible': visible,
      };

  factory ImagenCalibrada.fromJson(Map<String, dynamic> json) =>
      ImagenCalibrada(
        rutaArchivo: json['rutaArchivo'] as String,
        nombre: json['nombre'] as String,
        norte: (json['norte'] as num).toDouble(),
        sur: (json['sur'] as num).toDouble(),
        este: (json['este'] as num).toDouble(),
        oeste: (json['oeste'] as num).toDouble(),
        opacidad: (json['opacidad'] as num?)?.toDouble() ?? 0.85,
        visible: json['visible'] as bool? ?? true,
      );

  ImagenCalibrada copyWith({
    String? rutaArchivo,
    String? nombre,
    double? norte,
    double? sur,
    double? este,
    double? oeste,
    double? opacidad,
    bool? visible,
  }) =>
      ImagenCalibrada(
        rutaArchivo: rutaArchivo ?? this.rutaArchivo,
        nombre: nombre ?? this.nombre,
        norte: norte ?? this.norte,
        sur: sur ?? this.sur,
        este: este ?? this.este,
        oeste: oeste ?? this.oeste,
        opacidad: opacidad ?? this.opacidad,
        visible: visible ?? this.visible,
      );

  @override
  String toString() =>
      'ImagenCalibrada($nombre: N=$norte S=$sur E=$este O=$oeste)';
}
