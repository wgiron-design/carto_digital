import 'dart:convert';
import 'package:http/http.dart' as http;
import 'postgis_service.dart';
import '../models/jerarquia.dart';

class NivelApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? data;

  NivelApiException({required this.code, required this.message, this.data});

  @override
  String toString() => 'NivelApiException: [$code] $message';
}

class NivelResumen {
  final String id;
  final int numero;
  final int numeroLocales;
  final String? descripcion;
  final DateTime updatedAt;
  final int localesRegistrados;
  final int hogaresRegistrados;
  final int personasRegistradas;

  NivelResumen({
    required this.id,
    required this.numero,
    required this.numeroLocales,
    this.descripcion,
    required this.updatedAt,
    required this.localesRegistrados,
    required this.hogaresRegistrados,
    required this.personasRegistradas,
  });

  factory NivelResumen.fromJson(Map<String, dynamic> json) {
    return NivelResumen(
      id: json['id'] as String,
      numero: (json['numero'] as num).toInt(),
      numeroLocales: (json['numero_locales'] as num).toInt(),
      descripcion: json['descripcion'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      localesRegistrados: (json['locales_registrados'] as num).toInt(),
      hogaresRegistrados: (json['hogares_registrados'] as num).toInt(),
      personasRegistradas: (json['personas_registradas'] as num).toInt(),
    );
  }

  Nivel toNivelModel(String estructuraId) {
    return Nivel(
      id: id,
      idEstructura: estructuraId,
      numeroNivel: numero,
      numeroLocales: numeroLocales,
      descripcion: descripcion,
      updatedAt: updatedAt,
      syncDirty: false,
    );
  }
}

class NivelListResponse {
  final String estructuraId;
  final String nombreEstructura;
  final int nivelesCantidad;
  final int nivelesRegistrados;
  final List<NivelResumen> niveles;

  NivelListResponse({
    required this.estructuraId,
    required this.nombreEstructura,
    required this.nivelesCantidad,
    required this.nivelesRegistrados,
    required this.niveles,
  });

  factory NivelListResponse.fromJson(Map<String, dynamic> json) {
    return NivelListResponse(
      estructuraId: json['estructura_id'] as String,
      nombreEstructura: json['nombre_estructura'] as String? ?? 'Estructura',
      nivelesCantidad: (json['niveles_cantidad'] as num).toInt(),
      nivelesRegistrados: (json['niveles_registrados'] as num).toInt(),
      niveles: (json['niveles'] as List? ?? [])
          .map((n) => NivelResumen.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NivelService {
  static final NivelService _instance = NivelService._internal();
  factory NivelService() => _instance;
  NivelService._internal();

  String get _baseUrl => PostGISService().baseUrl;

  Future<NivelListResponse> getNivelesByEstructura(String estructuraId) async {
    final uri = Uri.parse('$_baseUrl/api/niveles/estructura/$estructuraId');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NivelListResponse.fromJson(data);
    } else {
      _handleError(response);
      throw NivelApiException(code: 'unknown_error', message: 'Error al consultar niveles');
    }
  }

  Future<Nivel> crearNivel(String estructuraId, {required int numeroLocales, String? descripcion}) async {
    final uri = Uri.parse('$_baseUrl/api/niveles/estructura/$estructuraId');
    final body = json.encode({
      'numero_locales': numeroLocales,
      if (descripcion != null) 'descripcion': descripcion,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Nivel.fromJson(data);
    } else {
      _handleError(response);
      throw NivelApiException(code: 'unknown_error', message: 'Error al crear nivel');
    }
  }

  Future<Nivel> editarNivel(String nivelId, {int? numeroLocales, String? descripcion}) async {
    final uri = Uri.parse('$_baseUrl/api/niveles/$nivelId');
    final payload = <String, dynamic>{};
    if (numeroLocales != null) payload['numero_locales'] = numeroLocales;
    if (descripcion != null) payload['descripcion'] = descripcion;

    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Nivel.fromJson(data);
    } else {
      _handleError(response);
      throw NivelApiException(code: 'unknown_error', message: 'Error al editar nivel');
    }
  }

  Future<Nivel> confirmarEliminacionLocales(String nivelId, int numeroLocalesNuevo) async {
    final uri = Uri.parse('$_baseUrl/api/niveles/$nivelId/locales-excedentes');
    final body = json.encode({
      'numero_locales_nuevo': numeroLocalesNuevo,
    });

    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Nivel.fromJson(data);
    } else {
      _handleError(response);
      throw NivelApiException(code: 'unknown_error', message: 'Error al confirmar eliminación de locales');
    }
  }

  void _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is Map) {
          throw NivelApiException(
            code: detail['error'] as String? ?? 'api_error',
            message: detail['message'] as String? ?? 'Ocurrió un error',
            data: detail['data'] as Map<String, dynamic>?,
          );
        } else if (detail is String) {
          throw NivelApiException(code: 'api_error', message: detail);
        }
      }
    } catch (e) {
      if (e is NivelApiException) rethrow;
    }
    throw NivelApiException(
      code: 'http_${response.statusCode}',
      message: 'Respuesta del servidor no válida (${response.statusCode})',
    );
  }
}
