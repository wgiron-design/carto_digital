import 'capa_geometrica.dart';

/// Modelo del proyecto de cartografía.
class ProyectoCartografico {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final String version;

  // Capas del proyecto
  final List<PuntoEstructura> puntos;
  final List<LineaCamino> lineas;
  final List<PoligonoUPM> poligonos;

  ProyectoCartografico({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.version = '1.0.0',
    this.puntos = const [],
    this.lineas = const [],
    this.poligonos = const [],
  });

  factory ProyectoCartografico.nuevo({
    required String nombre,
    String descripcion = '',
  }) {
    final ahora = DateTime.now();
    return ProyectoCartografico(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      descripcion: descripcion,
      fechaCreacion: ahora,
      fechaModificacion: ahora,
    );
  }

  factory ProyectoCartografico.fromJson(Map<String, dynamic> json) {
    return ProyectoCartografico(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaModificacion: DateTime.parse(json['fechaModificacion'] as String),
      version: json['version'] as String? ?? '1.0.0',
      puntos: (json['puntos'] as List? ?? [])
          .map((p) => PuntoEstructura.fromJson(p))
          .toList(),
      lineas: (json['lineas'] as List? ?? [])
          .map((l) => LineaCamino.fromJson(l))
          .toList(),
      poligonos: (json['poligonos'] as List? ?? [])
          .map((p) => PoligonoUPM.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion.toIso8601String(),
      'version': version,
      'puntos': puntos.map((p) => p.toJson()).toList(),
      'lineas': lineas.map((l) => l.toJson()).toList(),
      'poligonos': poligonos.map((p) => p.toJson()).toList(),
    };
  }

  ProyectoCartografico copyWith({
    String? nombre,
    String? descripcion,
    DateTime? fechaModificacion,
    List<PuntoEstructura>? puntos,
    List<LineaCamino>? lineas,
    List<PoligonoUPM>? poligonos,
  }) {
    return ProyectoCartografico(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion,
      fechaModificacion: fechaModificacion ?? DateTime.now(),
      version: version,
      puntos: puntos ?? this.puntos,
      lineas: lineas ?? this.lineas,
      poligonos: poligonos ?? this.poligonos,
    );
  }
}
