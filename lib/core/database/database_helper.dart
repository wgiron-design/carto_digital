import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:carto_digital/core/models/capa_geometrica.dart';
import 'package:carto_digital/core/models/jerarquia.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Uuid uuid = const Uuid();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    try {
      Directory? extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        dbPath = join(extDir.path, 'carto_digital.sqlite');
      } else {
        Directory docDir = await getApplicationDocumentsDirectory();
        dbPath = join(docDir.path, 'carto_digital.sqlite');
      }
    } catch (e) {
      Directory docDir = await getApplicationDocumentsDirectory();
      dbPath = join(docDir.path, 'carto_digital.sqlite');
    }

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE niveles ADD COLUMN numero_locales INTEGER DEFAULT 1');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE locales ADD COLUMN uso_actual TEXT');
      await db.execute('ALTER TABLE locales ADD COLUMN ocupacion TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE locales ADD COLUMN numero_hogares INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN total_habitantes INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN idioma TEXT');
      await db.execute('ALTER TABLE hogares ADD COLUMN sexo_jefe TEXT');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_0_5 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_6_11 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_12_17 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_18_23 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_24_34 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_35_44 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_45_59 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_60_69 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_70_79 INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_80_mas INTEGER');
      await db.execute('ALTER TABLE hogares ADD COLUMN personas_no_edad INTEGER');
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE upm (
        id TEXT PRIMARY KEY,
        geom_wkt TEXT,
        min_x REAL,
        max_x REAL,
        min_y REAL,
        max_y REAL,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE VIRTUAL TABLE upm_index USING rtree(
        id_index,
        min_x, max_x,
        min_y, max_y
      )
    ''');

    await db.execute('''
      CREATE TABLE caminos (
        id TEXT PRIMARY KEY,
        geom_wkt TEXT,
        min_x REAL,
        max_x REAL,
        min_y REAL,
        max_y REAL,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE VIRTUAL TABLE caminos_index USING rtree(
        id_index,
        min_x, max_x,
        min_y, max_y
      )
    ''');

    await db.execute('''
      CREATE TABLE estructuras (
        id TEXT PRIMARY KEY,
        upm_id TEXT,
        geom_wkt TEXT,
        x REAL,
        y REAL,
        nombre TEXT,
        notas TEXT,
        categoria TEXT,
        tipo_formal TEXT,
        tipo_referencia TEXT,
        estado TEXT,
        niveles_cantidad INTEGER,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1,
        FOREIGN KEY (upm_id) REFERENCES upm (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE VIRTUAL TABLE estructuras_index USING rtree(
        id_index,
        min_x, max_x,
        min_y, max_y
      )
    ''');

    await db.execute('''
      CREATE TABLE niveles (
        id TEXT PRIMARY KEY,
        estructura_id TEXT,
        numero INTEGER,
        numero_locales INTEGER DEFAULT 1,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1,
        FOREIGN KEY (estructura_id) REFERENCES estructuras (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE locales (
        id TEXT PRIMARY KEY,
        nivel_id TEXT,
        nombre TEXT,
        uso_actual TEXT,
        ocupacion TEXT,
        numero_hogares INTEGER,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1,
        FOREIGN KEY (nivel_id) REFERENCES niveles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hogares (
        id TEXT PRIMARY KEY,
        local_id TEXT,
        jefe_familia TEXT,
        sexo_jefe TEXT,
        idioma TEXT,
        total_habitantes INTEGER,
        personas_0_5 INTEGER,
        personas_6_11 INTEGER,
        personas_12_17 INTEGER,
        personas_18_23 INTEGER,
        personas_24_34 INTEGER,
        personas_35_44 INTEGER,
        personas_45_59 INTEGER,
        personas_60_69 INTEGER,
        personas_70_79 INTEGER,
        personas_80_mas INTEGER,
        personas_no_edad INTEGER,
        updated_at TEXT,
        sync_dirty INTEGER DEFAULT 1,
        FOREIGN KEY (local_id) REFERENCES locales (id) ON DELETE CASCADE
      )
    ''');
  }

  String _now() => DateTime.now().toIso8601String();

  Future<void> insertEntity(String table, Map<String, dynamic> data) async {
    final db = await database;
    if (!data.containsKey('id') || data['id'] == null) {
      data['id'] = uuid.v4();
    }
    data['updated_at'] = _now();
    data['sync_dirty'] = 1;
    int count = await db.update(table, data, where: 'id = ?', whereArgs: [data['id']]);
    if (count == 0) {
      await db.insert(table, data);
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<void> deleteEntity(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // OPERACIONES ESPECÍFICAS DE JERARQUÍA
  // ─────────────────────────────────────────────────────────────────────────────

  /// Guarda una estructura con toda su jerarquía (Niveles, Locales, Hogares)
  Future<void> saveEstructuraCompleta(PuntoEstructura estructura, {String upmId = 'default_upm'}) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Guardar estructura (Upsert seguro)
      final estMap = estructura.toMapDB(upmId);
      int countEst = await txn.update('estructuras', estMap, where: 'id = ?', whereArgs: [estructura.id]);
      if (countEst == 0) await txn.insert('estructuras', estMap);

      // 2. Limpiar niveles que fueron eliminados en UI
      final nivelIds = estructura.niveles.map((n) => n.id).toList();
      if (nivelIds.isNotEmpty) {
        await txn.delete('niveles', 
            where: 'estructura_id = ? AND id NOT IN (${List.filled(nivelIds.length, '?').join(', ')})', 
            whereArgs: [estructura.id, ...nivelIds]);
      } else {
        await txn.delete('niveles', where: 'estructura_id = ?', whereArgs: [estructura.id]);
      }

      for (var nivel in estructura.niveles) {
        final nivelMap = nivel.toMapDB();
        int countNiv = await txn.update('niveles', nivelMap, where: 'id = ?', whereArgs: [nivel.id]);
        if (countNiv == 0) await txn.insert('niveles', nivelMap);

        // Limpiar locales eliminados
        final localIds = nivel.locales.map((l) => l.id).toList();
        if (localIds.isNotEmpty) {
          await txn.delete('locales', 
              where: 'nivel_id = ? AND id NOT IN (${List.filled(localIds.length, '?').join(', ')})', 
              whereArgs: [nivel.id, ...localIds]);
        } else {
          await txn.delete('locales', where: 'nivel_id = ?', whereArgs: [nivel.id]);
        }

        for (var local in nivel.locales) {
          final localMap = local.toMapDB();
          int countLoc = await txn.update('locales', localMap, where: 'id = ?', whereArgs: [local.id]);
          if (countLoc == 0) await txn.insert('locales', localMap);

          // Limpiar hogares eliminados
          final hogarIds = local.hogares.map((h) => h.id).toList();
          if (hogarIds.isNotEmpty) {
            await txn.delete('hogares', 
                where: 'local_id = ? AND id NOT IN (${List.filled(hogarIds.length, '?').join(', ')})', 
                whereArgs: [local.id, ...hogarIds]);
          } else {
            await txn.delete('hogares', where: 'local_id = ?', whereArgs: [local.id]);
          }

          for (var hogar in local.hogares) {
            final hogarMap = hogar.toMapDB();
            int countHog = await txn.update('hogares', hogarMap, where: 'id = ?', whereArgs: [hogar.id]);
            if (countHog == 0) await txn.insert('hogares', hogarMap);
          }
        }
      }
    });
  }

  /// Recupera todas las estructuras y reconstruye su jerarquía de objetos
  Future<List<PuntoEstructura>> getEstructuras({String upmId = 'default_upm'}) async {
    final db = await database;
    
    // Obtener estructuras
    final estMaps = await db.query('estructuras', where: 'upm_id = ?', whereArgs: [upmId]);
    if (estMaps.isEmpty) return [];

    final estIds = estMaps.map((e) => e['id'] as String).toList();
    
    // Obtener todos los niveles
    final nivelesMaps = await db.query('niveles', 
      where: 'estructura_id IN (${List.filled(estIds.length, '?').join(', ')})',
      whereArgs: estIds);
    final nivelIds = nivelesMaps.map((n) => n['id'] as String).toList();

    // Obtener todos los locales
    List<Map<String, dynamic>> localesMaps = [];
    if (nivelIds.isNotEmpty) {
      localesMaps = await db.query('locales',
        where: 'nivel_id IN (${List.filled(nivelIds.length, '?').join(', ')})',
        whereArgs: nivelIds);
    }
    final localIds = localesMaps.map((l) => l['id'] as String).toList();

    // Obtener todos los hogares
    List<Map<String, dynamic>> hogaresMaps = [];
    if (localIds.isNotEmpty) {
      hogaresMaps = await db.query('hogares',
        where: 'local_id IN (${List.filled(localIds.length, '?').join(', ')})',
        whereArgs: localIds);
    }

    // Mapear Hogares por Local
    final Map<String, List<Hogar>> hogaresPorLocal = {};
    for (var hMap in hogaresMaps) {
      final hogar = Hogar(
        id: hMap['id'] as String,
        idLocal: hMap['local_id'] as String,
        jefeFamilia: hMap['jefe_familia'] as String? ?? '',
        sexoJefe: hMap['sexo_jefe'] as String?,
        idioma: hMap['idioma'] as String?,
        totalHabitantes: hMap['total_habitantes'] != null ? (hMap['total_habitantes'] as num).toInt() : null,
        personas_0_5: hMap['personas_0_5'] != null ? (hMap['personas_0_5'] as num).toInt() : null,
        personas_6_11: hMap['personas_6_11'] != null ? (hMap['personas_6_11'] as num).toInt() : null,
        personas_12_17: hMap['personas_12_17'] != null ? (hMap['personas_12_17'] as num).toInt() : null,
        personas_18_23: hMap['personas_18_23'] != null ? (hMap['personas_18_23'] as num).toInt() : null,
        personas_24_34: hMap['personas_24_34'] != null ? (hMap['personas_24_34'] as num).toInt() : null,
        personas_35_44: hMap['personas_35_44'] != null ? (hMap['personas_35_44'] as num).toInt() : null,
        personas_45_59: hMap['personas_45_59'] != null ? (hMap['personas_45_59'] as num).toInt() : null,
        personas_60_69: hMap['personas_60_69'] != null ? (hMap['personas_60_69'] as num).toInt() : null,
        personas_70_79: hMap['personas_70_79'] != null ? (hMap['personas_70_79'] as num).toInt() : null,
        personas_80_mas: hMap['personas_80_mas'] != null ? (hMap['personas_80_mas'] as num).toInt() : null,
        personasNoEdad: hMap['personas_no_edad'] != null ? (hMap['personas_no_edad'] as num).toInt() : null,
        updatedAt: DateTime.parse(hMap['updated_at'] as String),
        syncDirty: hMap['sync_dirty'] == 1,
      );
      hogaresPorLocal.putIfAbsent(hogar.idLocal, () => []).add(hogar);
    }

    // Mapear Locales por Nivel
    final Map<String, List<Local>> localesPorNivel = {};
    for (var lMap in localesMaps) {
      final local = Local(
        id: lMap['id'] as String,
        idNivel: lMap['nivel_id'] as String,
        nombre: lMap['nombre'] as String? ?? '',
        usoActual: lMap['uso_actual'] as String? ?? '',
        ocupacion: lMap['ocupacion'] as String?,
        numeroHogares: lMap['numero_hogares'] != null ? (lMap['numero_hogares'] as num).toInt() : null,
        updatedAt: DateTime.parse(lMap['updated_at'] as String),
        syncDirty: lMap['sync_dirty'] == 1,
        hogares: hogaresPorLocal[lMap['id']] ?? [],
      );
      localesPorNivel.putIfAbsent(local.idNivel, () => []).add(local);
    }

    // Mapear Niveles por Estructura
    final Map<String, List<Nivel>> nivelesPorEstructura = {};
    for (var nMap in nivelesMaps) {
      final nivel = Nivel(
        id: nMap['id'] as String,
        idEstructura: nMap['estructura_id'] as String,
        numeroNivel: (nMap['numero'] as num).toInt(),
        numeroLocales: (nMap['numero_locales'] as num?)?.toInt() ?? 1,
        updatedAt: DateTime.parse(nMap['updated_at'] as String),
        syncDirty: nMap['sync_dirty'] == 1,
        locales: localesPorNivel[nMap['id']] ?? [],
      );
      nivelesPorEstructura.putIfAbsent(nivel.idEstructura, () => []).add(nivel);
    }

    // Ensamblar Estructuras
    List<PuntoEstructura> estructuras = [];
    for (var estMap in estMaps) {
      final estructura = PuntoEstructura(
        id: estMap['id'] as String,
        coordenadas: LatLng(
          estMap['y'] as double,
          estMap['x'] as double,
        ),
        nombre: estMap['nombre'] as String? ?? '',
        categoria: CategoriaEstructura.values.firstWhere(
          (e) => e.name == estMap['categoria'],
          orElse: () => CategoriaEstructura.formal,
        ),
        tipoFormal: estMap['tipo_formal'] != null 
          ? TipoEstructuraFormal.values.firstWhere((e) => e.name == estMap['tipo_formal'], orElse: () => TipoEstructuraFormal.vivienda)
          : null,
        tipoReferencia: estMap['tipo_referencia'] != null
          ? TipoEstructuraReferencia.values.firstWhere((e) => e.name == estMap['tipo_referencia'], orElse: () => TipoEstructuraReferencia.puente)
          : null,
        estado: EstadoEstructura.values.firstWhere(
          (e) => e.name == estMap['estado'],
          orElse: () => EstadoEstructura.presente,
        ),
        nivelesCantidad: (estMap['niveles_cantidad'] as num?)?.toInt() ?? 1,
        notas: estMap['notas'] as String? ?? '',
        updatedAt: DateTime.parse(estMap['updated_at'] as String),
        syncDirty: estMap['sync_dirty'] == 1,
        niveles: nivelesPorEstructura[estMap['id']] ?? [],
      );
      estructuras.add(estructura);
    }
    return estructuras;
  }
}
