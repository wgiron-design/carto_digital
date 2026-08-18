import 'dart:convert';
import 'package:http/http.dart' as http;
import 'postgis_service.dart';
import '../models/capa_geometrica.dart';
import '../models/jerarquia.dart';

class HogarApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? data;

  HogarApiException({required this.code, required this.message, this.data});

  @override
  String toString() => 'HogarApiException: [$code] $message';
}

class HogarResumen {
  final String id;
  final String localId;
  final String? jefeFamilia;
  final int? idSexo;
  final String? nombreSexo;
  final int? idIdioma;
  final String? nombreIdioma;
  final String? direccion;
  final int totalHabitantes;
  final int personas_0_5;
  final int personas_6_11;
  final int personas_12_17;
  final int personas_18_23;
  final int personas_24_34;
  final int personas_35_44;
  final int personas_45_59;
  final int personas_60_69;
  final int personas_70_79;
  final int personas_80_mas;
  final int personasNoEdad;
  final DateTime? updatedAt;

  HogarResumen({
    required this.id,
    required this.localId,
    this.jefeFamilia,
    this.idSexo,
    this.nombreSexo,
    this.idIdioma,
    this.nombreIdioma,
    this.direccion,
    required this.totalHabitantes,
    required this.personas_0_5,
    required this.personas_6_11,
    required this.personas_12_17,
    required this.personas_18_23,
    required this.personas_24_34,
    required this.personas_35_44,
    required this.personas_45_59,
    required this.personas_60_69,
    required this.personas_70_79,
    required this.personas_80_mas,
    required this.personasNoEdad,
    this.updatedAt,
  });

  factory HogarResumen.fromJson(Map<String, dynamic> json) {
    return HogarResumen(
      id: json['id'] as String,
      localId: (json['local_id'] ?? json['id_local'] ?? '') as String,
      jefeFamilia: json['jefe_familia'] as String?,
      idSexo: json['id_sexo'] != null ? (json['id_sexo'] as num).toInt() : null,
      nombreSexo: json['nombre_sexo'] as String?,
      idIdioma: json['id_idioma'] != null ? (json['id_idioma'] as num).toInt() : null,
      nombreIdioma: json['nombre_idioma'] as String?,
      direccion: json['direccion'] as String?,
      totalHabitantes: (json['total_habitantes'] as num? ?? 0).toInt(),
      personas_0_5: (json['personas_0_5'] as num? ?? 0).toInt(),
      personas_6_11: (json['personas_6_11'] as num? ?? 0).toInt(),
      personas_12_17: (json['personas_12_17'] as num? ?? 0).toInt(),
      personas_18_23: (json['personas_18_23'] as num? ?? 0).toInt(),
      personas_24_34: (json['personas_24_34'] as num? ?? 0).toInt(),
      personas_35_44: (json['personas_35_44'] as num? ?? 0).toInt(),
      personas_45_59: (json['personas_45_59'] as num? ?? 0).toInt(),
      personas_60_69: (json['personas_60_69'] as num? ?? 0).toInt(),
      personas_70_79: (json['personas_70_79'] as num? ?? 0).toInt(),
      personas_80_mas: (json['personas_80_mas'] as num? ?? 0).toInt(),
      personasNoEdad: (json['personas_no_edad'] as num? ?? 0).toInt(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  int get sumaEdades {
    return personas_0_5 + personas_6_11 + personas_12_17 + personas_18_23 + personas_24_34 + personas_35_44 + personas_45_59 + personas_60_69 + personas_70_79 + personas_80_mas + personasNoEdad;
  }

  bool get esValidoMatematicamente {
    final suma = sumaEdades;
    return suma == 0 || totalHabitantes == suma;
  }

  Hogar toHogarModel() {
    return Hogar(
      id: id,
      idLocal: localId,
      jefeFamilia: jefeFamilia ?? '',
      idSexo: idSexo,
      idIdioma: idIdioma,
      nombreSexo: nombreSexo,
      nombreIdioma: nombreIdioma,
      direccion: direccion,
      totalHabitantes: totalHabitantes,
      personas_0_5: personas_0_5,
      personas_6_11: personas_6_11,
      personas_12_17: personas_12_17,
      personas_18_23: personas_18_23,
      personas_24_34: personas_24_34,
      personas_35_44: personas_35_44,
      personas_45_59: personas_45_59,
      personas_60_69: personas_60_69,
      personas_70_79: personas_70_79,
      personas_80_mas: personas_80_mas,
      personasNoEdad: personasNoEdad,
      updatedAt: updatedAt,
      syncDirty: false,
    );
  }
}

class HogarListResponse {
  final String localId;
  final String? nombreLocal;
  final int? numeroHogaresEsperados;
  final int? idTipoLocal;
  final int? idCondicionLocal;
  final int hogaresRegistrados;
  final List<HogarResumen> hogares;

  HogarListResponse({
    required this.localId,
    this.nombreLocal,
    this.numeroHogaresEsperados,
    this.idTipoLocal,
    this.idCondicionLocal,
    required this.hogaresRegistrados,
    required this.hogares,
  });

  factory HogarListResponse.fromJson(Map<String, dynamic> json) {
    return HogarListResponse(
      localId: json['local_id'] as String,
      nombreLocal: json['nombre_local'] as String?,
      numeroHogaresEsperados: json['numero_hogares_esperados'] != null ? (json['numero_hogares_esperados'] as num).toInt() : null,
      idTipoLocal: json['id_tipo_local'] != null ? (json['id_tipo_local'] as num).toInt() : null,
      idCondicionLocal: json['id_condicion_local'] != null ? (json['id_condicion_local'] as num).toInt() : null,
      hogaresRegistrados: (json['hogares_registrados'] as num).toInt(),
      hogares: (json['hogares'] as List? ?? [])
          .map((h) => HogarResumen.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get esCompleto {
    if (idCondicionLocal == 4 || idCondicionLocal == 5) return true; // Desocupado / Rechazo
    if (idTipoLocal == 4 || idTipoLocal == 5) return true;           // Institución / En Construcción
    if (numeroHogaresEsperados == null) return true;
    if (hogaresRegistrados < numeroHogaresEsperados!) return false;
    for (var hogar in hogares) {
      if (!hogar.esValidoMatematicamente) return false;
    }
    return true;
  }
}

class HogarService {
  static final HogarService _instance = HogarService._internal();
  factory HogarService() => _instance;
  HogarService._internal();

  String get _baseUrl => PostGISService().baseUrl;

  Future<List<CatalogoItem>> getSexos() async {
    final uri = Uri.parse('$_baseUrl/api/capas/catalogos/hogares/sexo');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((item) => CatalogoItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al consultar catálogo de sexo');
    }
  }

  Future<List<CatalogoItem>> getIdiomas() async {
    final uri = Uri.parse('$_baseUrl/api/capas/catalogos/hogares/idiomas');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((item) => CatalogoItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al consultar catálogo de idiomas');
    }
  }

  Future<HogarListResponse> getHogaresByLocal(String localId) async {
    final uri = Uri.parse('$_baseUrl/api/hogares/local/$localId');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HogarListResponse.fromJson(data);
    } else {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al consultar hogares');
    }
  }

  Future<Hogar> crearHogar(
    String localId, {
    String? jefeFamilia,
    int? idSexo,
    int? idIdioma,
    String? direccion,
    int? totalHabitantes,
    int? p0_5, int? p6_11, int? p12_17, int? p18_23,
    int? p24_34, int? p35_44, int? p45_59, int? p60_69,
    int? p70_79, int? p80mas, int? pNoEdad,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/hogares/local/$localId');
    final body = json.encode({
      if (jefeFamilia != null && jefeFamilia.isNotEmpty) 'jefe_familia': jefeFamilia,
      if (idSexo != null) 'id_sexo': idSexo,
      if (idIdioma != null) 'id_idioma': idIdioma,
      if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      'total_habitantes': totalHabitantes ?? 0,
      'personas_0_5': p0_5 ?? 0,
      'personas_6_11': p6_11 ?? 0,
      'personas_12_17': p12_17 ?? 0,
      'personas_18_23': p18_23 ?? 0,
      'personas_24_34': p24_34 ?? 0,
      'personas_35_44': p35_44 ?? 0,
      'personas_45_59': p45_59 ?? 0,
      'personas_60_69': p60_69 ?? 0,
      'personas_70_79': p70_79 ?? 0,
      'personas_80_mas': p80mas ?? 0,
      'personas_no_edad': pNoEdad ?? 0,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Hogar.fromJson(data);
    } else {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al crear hogar');
    }
  }

  Future<Hogar> editarHogar(
    String hogarId, {
    String? jefeFamilia,
    int? idSexo,
    int? idIdioma,
    String? direccion,
    int? totalHabitantes,
    int? p0_5, int? p6_11, int? p12_17, int? p18_23,
    int? p24_34, int? p35_44, int? p45_59, int? p60_69,
    int? p70_79, int? p80mas, int? pNoEdad,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/hogares/$hogarId');
    final payload = <String, dynamic>{};
    if (jefeFamilia != null) payload['jefe_familia'] = jefeFamilia;
    if (idSexo != null) payload['id_sexo'] = idSexo;
    if (idIdioma != null) payload['id_idioma'] = idIdioma;
    if (direccion != null) payload['direccion'] = direccion;
    if (totalHabitantes != null) payload['total_habitantes'] = totalHabitantes;
    if (p0_5 != null) payload['personas_0_5'] = p0_5;
    if (p6_11 != null) payload['personas_6_11'] = p6_11;
    if (p12_17 != null) payload['personas_12_17'] = p12_17;
    if (p18_23 != null) payload['personas_18_23'] = p18_23;
    if (p24_34 != null) payload['personas_24_34'] = p24_34;
    if (p35_44 != null) payload['personas_35_44'] = p35_44;
    if (p45_59 != null) payload['personas_45_59'] = p45_59;
    if (p60_69 != null) payload['personas_60_69'] = p60_69;
    if (p70_79 != null) payload['personas_70_79'] = p70_79;
    if (p80mas != null) payload['personas_80_mas'] = p80mas;
    if (pNoEdad != null) payload['personas_no_edad'] = pNoEdad;

    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Hogar.fromJson(data);
    } else {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al editar hogar');
    }
  }

  Future<void> eliminarHogar(String hogarId) async {
    final uri = Uri.parse('$_baseUrl/api/hogares/$hogarId');
    final response = await http.delete(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      _handleError(response);
      throw HogarApiException(code: 'unknown_error', message: 'Error al eliminar hogar');
    }
  }

  void _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is Map) {
          throw HogarApiException(
            code: detail['error'] as String? ?? 'api_error',
            message: detail['message'] as String? ?? 'Ocurrió un error',
            data: detail['data'] as Map<String, dynamic>?,
          );
        } else if (detail is String) {
          throw HogarApiException(code: 'api_error', message: detail);
        }
      }
    } catch (e) {
      if (e is HogarApiException) rethrow;
    }
    throw HogarApiException(
      code: 'http_${response.statusCode}',
      message: 'Respuesta del servidor no válida (${response.statusCode})',
    );
  }
}
