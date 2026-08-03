import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resultado de una operación de almacenamiento
class StorageResult {
  final bool exito;
  final String? mensaje;
  final String? rutaArchivo;
  final dynamic datos;

  const StorageResult({
    required this.exito,
    this.mensaje,
    this.rutaArchivo,
    this.datos,
  });

  factory StorageResult.ok({
    String? mensaje,
    String? rutaArchivo,
    dynamic datos,
  }) =>
      StorageResult(
          exito: true,
          mensaje: mensaje,
          rutaArchivo: rutaArchivo,
          datos: datos);

  factory StorageResult.error(String mensaje) =>
      StorageResult(exito: false, mensaje: mensaje);
}

/// Servicio de almacenamiento usando Storage Access Framework (SAF)
/// Compatible con Android 14 (API 34)
///
/// ARQUITECTURA:
/// ┌─────────────────────────────┐
/// │   Flutter (Dart)            │
/// │   StorageSAFService         │
/// │   - file_picker             │  ─── selección de carpeta (SAF picker)
/// │   - MethodChannel           │  ─── operaciones nativas Android
/// └─────────────────────────────┘
///              │
///     MethodChannel "com.cartodigital/saf"
///              │
/// ┌─────────────────────────────┐
/// │   Android (Kotlin)          │
/// │   MainActivity.kt           │
/// │   - takePersistableUri...   │  ─── hace el permiso PERSISTENTE
/// │   - ContentResolver         │  ─── lee/escribe archivos via URI
/// │   - DocumentFile            │  ─── navega el árbol de carpetas
/// └─────────────────────────────┘
///
/// Por qué este enfoque:
/// 1. `shared_storage` fue DESCONTINUADO (Feb 2024, no hay mantenimiento)
/// 2. `file_picker` es activo y mantenido por la comunidad Flutter
/// 3. La persistencia de URI REQUIERE código nativo (no hay alternativa pura Dart)
/// 4. `DocumentFile` de Android es la API oficial para SAF desde API 21+
class StorageSAFService extends ChangeNotifier {
  // Canal de comunicación con el código nativo Kotlin
  static const MethodChannel _channel = MethodChannel('com.cartodigital/saf');

  /// URI persistente de la carpeta autorizada por el usuario vía SAF
  Uri? _carpetaUri;

  /// URI del último archivo escrito/leído
  Uri? _archivoUri;

  bool _inicializado = false;

  Uri? get carpetaUri => _carpetaUri;
  Uri? get archivoUri => _archivoUri;
  bool get inicializado => _inicializado;
  bool get tieneCarpeta => _carpetaUri != null;

  // ──────────────────────────────────────────────────────────────────────────
  // GESTIÓN DE PERMISOS
  // ──────────────────────────────────────────────────────────────────────────

  /// Solicita al usuario que seleccione una carpeta mediante el selector SAF.
  ///
  /// Flujo:
  /// 1. `file_picker.getDirectoryPath()` abre el selector del sistema Android
  /// 2. El usuario navega a "Documentos" y toca [Seleccionar]
  /// 3. El sistema retorna un URI de tipo `content://...`
  /// 4. Llamamos al MethodChannel para hacer ese permiso PERSISTENTE
  ///    (sin este paso, el permiso se pierde al reiniciar el dispositivo)
  Future<StorageResult> solicitarCarpeta() async {
    try {
      String? rutaSeleccionada;
      
      if (kIsWeb || !Platform.isAndroid) {
        // Fallback for non-Android
        rutaSeleccionada = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Selecciona una carpeta base. Se creará una subcarpeta "INE"',
          lockParentWindow: true,
        );
      } else {
        // Usa el selector nativo SAF que creamos en MainActivity
        rutaSeleccionada = await _channel.invokeMethod<String>('requestDirectoryAccess');
      }

      if (rutaSeleccionada == null) {
        return StorageResult.error('El usuario canceló la selección.');
      }

      debugPrint('[SAF] Ruta seleccionada: $rutaSeleccionada');

      final Uri uri = Uri.parse(rutaSeleccionada);

      _carpetaUri = uri;
      _inicializado = true;
      notifyListeners();

      return StorageResult.ok(
        mensaje: 'Carpeta autorizada correctamente.',
        rutaArchivo: rutaSeleccionada,
      );
    } on PlatformException catch (e) {
      return StorageResult.error(
          'Error nativo al persistir permiso: ${e.message}');
    } catch (e) {
      return StorageResult.error('Error al solicitar carpeta: $e');
    }
  }

  /// Verifica si ya existen permisos persistentes de sesiones anteriores.
  /// Llamar al iniciar la app para restaurar acceso sin molestar al usuario.
  ///
  /// Si el usuario ya autorizó la carpeta antes, este método restaura
  /// el acceso automáticamente (incluso después de reiniciar el dispositivo).
  Future<bool> restaurarPermisosPersistentes() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return false;

      final List<dynamic>? uris =
          await _channel.invokeListMethod('getPersistedPermissions');

      debugPrint('[SAF] URIs persistentes encontrados: ${uris?.length ?? 0}');

      if (uris != null && uris.isNotEmpty) {
        // Usamos el primer URI persistente disponible
        _carpetaUri = Uri.parse(uris.first as String);
        _inicializado = true;
        notifyListeners();
        debugPrint('[SAF] Permiso restaurado: $_carpetaUri');
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('[SAF] Error al consultar permisos persistentes: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[SAF] Error inesperado: $e');
      return false;
    }
  }

  /// Revoca los permisos persistentes y limpia el estado interno.
  Future<void> revocarPermisos() async {
    if (_carpetaUri != null) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          await _channel.invokeMethod('releasePermission', {
            'uri': _carpetaUri.toString(),
          });
        }
      } on PlatformException catch (e) {
        debugPrint('[SAF] No se pudo revocar el permiso: ${e.message}');
      }
      _carpetaUri = null;
      _archivoUri = null;
      _inicializado = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OPERACIONES DE ARCHIVO
  // ──────────────────────────────────────────────────────────────────────────

  /// Escribe contenido JSON en un archivo dentro de la carpeta autorizada.
  /// Crea el archivo si no existe. Sobreescribe si ya existe.
  Future<StorageResult> escribirJson({
    required String nombreArchivo,
    required Map<String, dynamic> contenido,
  }) async {
    if (_carpetaUri == null) {
      return StorageResult.error(
          'No hay carpeta autorizada. Selecciona una carpeta primero.');
    }

    try {
      final String jsonString =
          const JsonEncoder.withIndent('  ').convert(contenido);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

      if (kIsWeb || !Platform.isAndroid) {
        return StorageResult.error('Guardado no soportado en esta plataforma.');
      }

      final String? archivoUri = await _channel.invokeMethod<String>(
        'writeFile',
        {
          'folderUri': _carpetaUri.toString(),
          'fileName': nombreArchivo,
          'mimeType': 'application/json',
          'bytes': bytes,
        },
      );

      if (archivoUri == null) {
        return StorageResult.error('El sistema no retornó el URI del archivo.');
      }

      _archivoUri = Uri.parse(archivoUri);
      notifyListeners();

      debugPrint('[SAF] Archivo escrito: $archivoUri (${bytes.length} bytes)');
      return StorageResult.ok(
        mensaje: 'Archivo guardado correctamente.',
        rutaArchivo: archivoUri,
      );
    } on PlatformException catch (e) {
      return StorageResult.error('Error nativo al escribir: ${e.message}');
    } catch (e) {
      return StorageResult.error('Error al escribir archivo: $e');
    }
  }

  /// Lee un archivo JSON de la carpeta autorizada y retorna su contenido parseado.
  Future<StorageResult> leerJson(String nombreArchivo) async {
    if (_carpetaUri == null) {
      return StorageResult.error('No hay carpeta autorizada.');
    }

    try {
      if (kIsWeb || !Platform.isAndroid) {
        return StorageResult.error('Lectura no soportada en esta plataforma.');
      }

      final Uint8List? bytes = await _channel.invokeMethod<Uint8List>(
        'readFile',
        {
          'folderUri': _carpetaUri.toString(),
          'fileName': nombreArchivo,
        },
      );

      if (bytes == null) {
        return StorageResult.error('El archivo está vacío o no se pudo leer.');
      }

      final String jsonString = utf8.decode(bytes);
      final Map<String, dynamic> datos = json.decode(jsonString);

      debugPrint('[SAF] Archivo leído: $nombreArchivo (${bytes.length} bytes)');

      return StorageResult.ok(
        mensaje: 'Archivo leído correctamente.',
        datos: datos,
      );
    } on PlatformException catch (e) {
      if (e.code == 'FILE_NOT_FOUND') {
        return StorageResult.error('Archivo no encontrado: $nombreArchivo');
      }
      return StorageResult.error('Error nativo al leer: ${e.message}');
    } catch (e) {
      return StorageResult.error('Error al leer archivo: $e');
    }
  }

  /// Lista todos los archivos JSON en la carpeta autorizada.
  /// Retorna lista de mapas con keys: name, uri, size
  Future<List<Map<String, String>>> listarArchivosJson() async {
    if (_carpetaUri == null) return [];

    try {
      if (kIsWeb || !Platform.isAndroid) return [];

      final List<dynamic>? archivos =
          await _channel.invokeListMethod('listJsonFiles', {
        'folderUri': _carpetaUri.toString(),
      });

      if (archivos == null) return [];

      return archivos
          .cast<Map<dynamic, dynamic>>()
          .map((a) => {
                'name': a['name'] as String,
                'uri': a['uri'] as String,
                'size': a['size'] as String,
              })
          .toList();
    } on PlatformException catch (e) {
      debugPrint('[SAF] Error al listar archivos: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[SAF] Error inesperado al listar: $e');
      return [];
    }
  }
}
