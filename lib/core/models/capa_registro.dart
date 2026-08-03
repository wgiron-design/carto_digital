class CapaRegistro {
  final String id;
  final String nombre;
  final String tipoGeometria; // 'POINT', 'LINESTRING', 'POLYGON'
  final String tablaOrigen;
  final String? descripcion;
  final String icono;
  final String color;
  final bool activa;
  final int ordenVisualizacion;

  CapaRegistro({
    required this.id,
    required this.nombre,
    required this.tipoGeometria,
    required this.tablaOrigen,
    this.descripcion,
    required this.icono,
    required this.color,
    required this.activa,
    required this.ordenVisualizacion,
  });

  factory CapaRegistro.fromJson(Map<String, dynamic> json) {
    return CapaRegistro(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipoGeometria: json['tipo_geometria'] as String,
      tablaOrigen: json['tabla_origen'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String? ?? 'layers',
      color: json['color'] as String? ?? '#4FC3F7',
      activa: json['activa'] as bool? ?? true,
      ordenVisualizacion: (json['orden_visualizacion'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo_geometria': tipoGeometria,
        'tabla_origen': tablaOrigen,
        'descripcion': descripcion,
        'icono': icono,
        'color': color,
        'activa': activa,
        'orden_visualizacion': ordenVisualizacion,
      };

  CapaRegistro copyWith({
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
    bool? activa,
    int? ordenVisualizacion,
  }) {
    return CapaRegistro(
      id: id,
      nombre: nombre ?? this.nombre,
      tipoGeometria: tipoGeometria,
      tablaOrigen: tablaOrigen,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      activa: activa ?? this.activa,
      ordenVisualizacion: ordenVisualizacion ?? this.ordenVisualizacion,
    );
  }
}
