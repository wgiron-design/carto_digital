import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS JERÁRQUICOS — Paso 4
//
// Estructura de datos (sin geometría propia):
//
//  PuntoEstructura (georreferenciado — Paso 3)
//    └── Nivel          (id, estructura_id, numero)
//          └── Local    (id, nivel_id, nombre, uso)
//                └── Hogar  (id, local_id, jefe_familia)
//
// Todas las relaciones son uno-a-muchos.
// Solo el Punto tiene coordenadas geográficas.
// ─────────────────────────────────────────────────────────────────────────────

const _uuid = Uuid();

/// Representa un nivel (piso) dentro de una estructura.
class Nivel {
  final String id;
  final String idEstructura;
  final int numeroNivel;
  final int numeroLocales;
  final String? descripcion;
  final DateTime updatedAt;
  final bool syncDirty;
  final List<Local> locales;

  Nivel({
    required this.id,
    required this.idEstructura,
    required this.numeroNivel,
    this.numeroLocales = 1,
    this.descripcion,
    DateTime? updatedAt,
    this.syncDirty = true,
    List<Local>? locales,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        locales = locales ?? [];

  /// Crea un nuevo Nivel con ID autogenerado
  factory Nivel.nuevo({
    required String idEstructura,
    required int numeroNivel,
    int numeroLocales = 1,
    String? descripcion,
  }) {
    return Nivel(
      id: _uuid.v4(),
      idEstructura: idEstructura,
      numeroNivel: numeroNivel,
      numeroLocales: numeroLocales,
      descripcion: descripcion,
      syncDirty: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_estructura': idEstructura,
        'numero_nivel': numeroNivel,
        'numero_locales': numeroLocales,
        'descripcion': descripcion,
        'updated_at': updatedAt.toIso8601String(),
        'sync_dirty': syncDirty ? 1 : 0,
        'locales': locales.map((l) => l.toJson()).toList(),
      };

  factory Nivel.fromJson(Map<String, dynamic> json) => Nivel(
        id: json['id'] as String,
        idEstructura: (json['id_estructura'] ?? json['estructura_id'] ?? '') as String,
        numeroNivel: ((json['numero_nivel'] ?? json['numero']) as num).toInt(),
        numeroLocales: json['numero_locales'] != null ? (json['numero_locales'] as num).toInt() : 1,
        descripcion: json['descripcion'] as String?,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
        syncDirty: json['sync_dirty'] == 1 || json['sync_dirty'] == true,
        locales: (json['locales'] as List? ?? [])
            .map((l) => Local.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMapDB() {
    return {
      'id': id,
      'estructura_id': idEstructura,
      'numero': numeroNivel,
      'numero_locales': numeroLocales,
      'descripcion': descripcion,
      'updated_at': updatedAt.toIso8601String(),
      'sync_dirty': syncDirty ? 1 : 0,
    };
  }

  Nivel copyWith({int? numeroNivel, int? numeroLocales, String? descripcion, List<Local>? locales}) => Nivel(
        id: id,
        idEstructura: idEstructura,
        numeroNivel: numeroNivel ?? this.numeroNivel,
        numeroLocales: numeroLocales ?? this.numeroLocales,
        descripcion: descripcion ?? this.descripcion,
        updatedAt: DateTime.now(),
        syncDirty: true,
        locales: locales ?? this.locales,
      );

  int get totalLocales => locales.length;
  int get totalHogares => locales.fold(0, (sum, l) => sum + l.hogares.length);

  @override
  String toString() => 'Nivel #$numeroNivel ($totalLocales locales)';
}

// ─────────────────────────────────────────────────────────────────────────────

/// Representa un local (vivienda, comercio, apartamento) dentro de un nivel.
class Local {
  final String id;
  final String idNivel;
  final String nombre;
  final String usoActual;
  final String? ocupacion;
  final int? numeroHogares;
  final DateTime updatedAt;
  final bool syncDirty;
  final List<Hogar> hogares;

  Local({
    required this.id,
    required this.idNivel,
    required this.nombre,
    required this.usoActual,
    this.ocupacion,
    this.numeroHogares,
    DateTime? updatedAt,
    this.syncDirty = true,
    List<Hogar>? hogares,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        hogares = hogares ?? [];

  factory Local.nuevo({
    required String idNivel,
    required String nombre,
    required String usoActual,
    String? ocupacion,
    int? numeroHogares,
  }) {
    return Local(
      id: _uuid.v4(),
      idNivel: idNivel,
      nombre: nombre,
      usoActual: usoActual,
      ocupacion: ocupacion,
      numeroHogares: numeroHogares,
      syncDirty: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_nivel': idNivel,
        'nombre': nombre,
        'uso_actual': usoActual,
        'ocupacion': ocupacion,
        'numero_hogares': numeroHogares,
        'updated_at': updatedAt.toIso8601String(),
        'sync_dirty': syncDirty ? 1 : 0,
        'hogares': hogares.map((h) => h.toJson()).toList(),
      };

  factory Local.fromJson(Map<String, dynamic> json) => Local(
        id: json['id'] as String,
        idNivel: json['id_nivel'] as String,
        nombre: json['nombre'] as String? ?? '',
        usoActual: json['uso_actual'] as String? ?? '',
        ocupacion: json['ocupacion'] as String?,
        numeroHogares: json['numero_hogares'] != null ? (json['numero_hogares'] as num).toInt() : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
        syncDirty: json['sync_dirty'] == 1 || json['sync_dirty'] == true,
        hogares: (json['hogares'] as List? ?? [])
            .map((h) => Hogar.fromJson(h as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMapDB() {
    return {
      'id': id,
      'nivel_id': idNivel,
      'nombre': nombre,
      'uso_actual': usoActual,
      'ocupacion': ocupacion,
      'numero_hogares': numeroHogares,
      'updated_at': updatedAt.toIso8601String(),
      'sync_dirty': syncDirty ? 1 : 0,
    };
  }

  Local copyWith({String? nombre, String? usoActual, String? ocupacion, int? numeroHogares, List<Hogar>? hogares}) => Local(
        id: id,
        idNivel: idNivel,
        nombre: nombre ?? this.nombre,
        usoActual: usoActual ?? this.usoActual,
        ocupacion: ocupacion ?? this.ocupacion,
        numeroHogares: numeroHogares ?? this.numeroHogares,
        updatedAt: DateTime.now(),
        syncDirty: true,
        hogares: hogares ?? this.hogares,
      );

  int get totalHogares => hogares.length;

  @override
  String toString() => 'Local $nombre ($totalHogares hogares)';
}

// ─────────────────────────────────────────────────────────────────────────────

/// Representa un hogar dentro de un local.
class Hogar {
  final String id;
  final String idLocal;
  final String jefeFamilia;
  final String? sexoJefe;
  final String? idioma;
  final int? totalHabitantes;
  final int? personas_0_5;
  final int? personas_6_11;
  final int? personas_12_17;
  final int? personas_18_23;
  final int? personas_24_34;
  final int? personas_35_44;
  final int? personas_45_59;
  final int? personas_60_69;
  final int? personas_70_79;
  final int? personas_80_mas;
  final int? personasNoEdad;
  final DateTime updatedAt;
  final bool syncDirty;

  Hogar({
    required this.id,
    required this.idLocal,
    required this.jefeFamilia,
    this.sexoJefe,
    this.idioma,
    this.totalHabitantes,
    this.personas_0_5,
    this.personas_6_11,
    this.personas_12_17,
    this.personas_18_23,
    this.personas_24_34,
    this.personas_35_44,
    this.personas_45_59,
    this.personas_60_69,
    this.personas_70_79,
    this.personas_80_mas,
    this.personasNoEdad,
    DateTime? updatedAt,
    this.syncDirty = true,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Hogar.nuevo({
    required String idLocal,
    required String jefeFamilia,
    String? sexoJefe,
  }) {
    return Hogar(
      id: _uuid.v4(),
      idLocal: idLocal,
      jefeFamilia: jefeFamilia,
      sexoJefe: sexoJefe,
      syncDirty: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_local': idLocal,
        'jefe_familia': jefeFamilia,
        'sexo_jefe': sexoJefe,
        'idioma': idioma,
        'total_habitantes': totalHabitantes,
        'personas_0_5': personas_0_5,
        'personas_6_11': personas_6_11,
        'personas_12_17': personas_12_17,
        'personas_18_23': personas_18_23,
        'personas_24_34': personas_24_34,
        'personas_35_44': personas_35_44,
        'personas_45_59': personas_45_59,
        'personas_60_69': personas_60_69,
        'personas_70_79': personas_70_79,
        'personas_80_mas': personas_80_mas,
        'personas_no_edad': personasNoEdad,
        'updated_at': updatedAt.toIso8601String(),
        'sync_dirty': syncDirty ? 1 : 0,
      };

  factory Hogar.fromJson(Map<String, dynamic> json) => Hogar(
        id: json['id'] as String,
        idLocal: json['id_local'] as String,
        jefeFamilia: json['jefe_familia'] as String? ?? '',
        sexoJefe: json['sexo_jefe'] as String?,
        idioma: json['idioma'] as String?,
        totalHabitantes: json['total_habitantes'] != null ? (json['total_habitantes'] as num).toInt() : null,
        personas_0_5: json['personas_0_5'] != null ? (json['personas_0_5'] as num).toInt() : null,
        personas_6_11: json['personas_6_11'] != null ? (json['personas_6_11'] as num).toInt() : null,
        personas_12_17: json['personas_12_17'] != null ? (json['personas_12_17'] as num).toInt() : null,
        personas_18_23: json['personas_18_23'] != null ? (json['personas_18_23'] as num).toInt() : null,
        personas_24_34: json['personas_24_34'] != null ? (json['personas_24_34'] as num).toInt() : null,
        personas_35_44: json['personas_35_44'] != null ? (json['personas_35_44'] as num).toInt() : null,
        personas_45_59: json['personas_45_59'] != null ? (json['personas_45_59'] as num).toInt() : null,
        personas_60_69: json['personas_60_69'] != null ? (json['personas_60_69'] as num).toInt() : null,
        personas_70_79: json['personas_70_79'] != null ? (json['personas_70_79'] as num).toInt() : null,
        personas_80_mas: json['personas_80_mas'] != null ? (json['personas_80_mas'] as num).toInt() : null,
        personasNoEdad: json['personas_no_edad'] != null ? (json['personas_no_edad'] as num).toInt() : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
        syncDirty: json['sync_dirty'] == 1 || json['sync_dirty'] == true,
      );

  Map<String, dynamic> toMapDB() {
    return {
      'id': id,
      'local_id': idLocal,
      'jefe_familia': jefeFamilia,
      'sexo_jefe': sexoJefe,
      'idioma': idioma,
      'total_habitantes': totalHabitantes,
      'personas_0_5': personas_0_5,
      'personas_6_11': personas_6_11,
      'personas_12_17': personas_12_17,
      'personas_18_23': personas_18_23,
      'personas_24_34': personas_24_34,
      'personas_35_44': personas_35_44,
      'personas_45_59': personas_45_59,
      'personas_60_69': personas_60_69,
      'personas_70_79': personas_70_79,
      'personas_80_mas': personas_80_mas,
      'personas_no_edad': personasNoEdad,
      'updated_at': updatedAt.toIso8601String(),
      'sync_dirty': syncDirty ? 1 : 0,
    };
  }

  Hogar copyWith({
    String? jefeFamilia,
    String? sexoJefe,
    String? idioma,
    int? totalHabitantes,
    int? personas_0_5,
    int? personas_6_11,
    int? personas_12_17,
    int? personas_18_23,
    int? personas_24_34,
    int? personas_35_44,
    int? personas_45_59,
    int? personas_60_69,
    int? personas_70_79,
    int? personas_80_mas,
    int? personasNoEdad,
  }) =>
      Hogar(
        id: id,
        idLocal: idLocal,
        jefeFamilia: jefeFamilia ?? this.jefeFamilia,
        sexoJefe: sexoJefe ?? this.sexoJefe,
        idioma: idioma ?? this.idioma,
        totalHabitantes: totalHabitantes ?? this.totalHabitantes,
        personas_0_5: personas_0_5 ?? this.personas_0_5,
        personas_6_11: personas_6_11 ?? this.personas_6_11,
        personas_12_17: personas_12_17 ?? this.personas_12_17,
        personas_18_23: personas_18_23 ?? this.personas_18_23,
        personas_24_34: personas_24_34 ?? this.personas_24_34,
        personas_35_44: personas_35_44 ?? this.personas_35_44,
        personas_45_59: personas_45_59 ?? this.personas_45_59,
        personas_60_69: personas_60_69 ?? this.personas_60_69,
        personas_70_79: personas_70_79 ?? this.personas_70_79,
        personas_80_mas: personas_80_mas ?? this.personas_80_mas,
        personasNoEdad: personasNoEdad ?? this.personasNoEdad,
        updatedAt: DateTime.now(),
        syncDirty: true,
      );

  @override
  String toString() => 'Hogar: $jefeFamilia';
}
