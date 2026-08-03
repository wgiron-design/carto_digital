package com.cartodigital.carto_digital

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity con MethodChannel para operaciones SAF (Storage Access Framework).
 *
 * ARQUITECTURA:
 * Flutter (Dart) ──── MethodChannel "com.cartodigital/saf" ────► MainActivity (Kotlin)
 *                                                                      │
 *                                                                      ▼
 *                                                             Android ContentResolver
 *                                                             (takePersistableUriPermission,
 *                                                              openOutputStream, etc.)
 *
 * Por qué necesitamos código nativo:
 * - `takePersistableUriPermission()` solo existe en la API nativa de Android.
 * - Los permisos SAF son "otorgables" (takeable) solo desde Activity, no desde Dart.
 * - Sin esto, los permisos se PIERDEN al reiniciar el dispositivo.
 */
class MainActivity : FlutterActivity() {

    private val SAF_CHANNEL = "com.cartodigital/saf"
    private val DIRECTORY_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SAF_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDirectoryAccess" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    startActivityForResult(intent, DIRECTORY_REQUEST_CODE)
                }

                /**
                 * Convierte un permiso SAF temporal en PERSISTENTE.
                 * Debe llamarse justo después de que el usuario seleccione una carpeta.
                 *
                 * Argumentos: { "uri": "content://com.android.externalstorage..." }
                 * Retorna: true si tuvo éxito
                 */
                "takePersistablePermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_URI", "El URI no puede ser nulo", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PERMISSION_ERROR", e.message, null)
                    }
                }

                /**
                 * Retorna la lista de URIs con permisos persistentes activos.
                 * Útil para restaurar el acceso sin pedir permisos de nuevo al usuario.
                 *
                 * Retorna: List<String> con los URIs persistentes
                 */
                "getPersistedPermissions" -> {
                    try {
                        val persistedPermissions = contentResolver.persistedUriPermissions
                        val uris = persistedPermissions
                            .filter { it.isReadPermission && it.isWritePermission }
                            .map { it.uri.toString() }
                        result.success(uris)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }

                /**
                 * Revoca un permiso persistente.
                 *
                 * Argumentos: { "uri": "content://..." }
                 * Retorna: true si tuvo éxito
                 */
                "releasePermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_URI", "El URI no puede ser nulo", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.releasePersistableUriPermission(uri, flags)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RELEASE_ERROR", e.message, null)
                    }
                }

                /**
                 * Escribe bytes en un archivo dentro de una carpeta SAF.
                 * Crea el archivo si no existe, sobreescribe si ya existe.
                 *
                 * Argumentos: {
                 *   "folderUri": "content://...",
                 *   "fileName": "proyecto.json",
                 *   "mimeType": "application/json",
                 *   "bytes": List<Int>  (contenido del archivo)
                 * }
                 * Retorna: String con el URI del archivo creado/actualizado
                 */
                "writeFile" -> {
                    val folderUriStr = call.argument<String>("folderUri")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType") ?: "application/json"
                    val bytes = call.argument<ByteArray>("bytes")

                    if (folderUriStr == null || fileName == null || bytes == null) {
                        result.error("INVALID_ARGS", "folderUri, fileName y bytes son requeridos", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val folderUri = Uri.parse(folderUriStr)
                        val folderDocument = androidx.documentfile.provider.DocumentFile
                            .fromTreeUri(applicationContext, folderUri)

                        if (folderDocument == null || !folderDocument.exists()) {
                            result.error("FOLDER_NOT_FOUND", "La carpeta no existe o no es accesible", null)
                            return@setMethodCallHandler
                        }

                        // Obtener o crear la subcarpeta "INE"
                        var targetFolder = folderDocument.findFile("INE")
                        if (targetFolder == null || !targetFolder.isDirectory) {
                            targetFolder = folderDocument.createDirectory("INE")
                        }
                        if (targetFolder == null) {
                            result.error("FOLDER_ERROR", "No se pudo crear o acceder a la carpeta INE", null)
                            return@setMethodCallHandler
                        }

                        // Buscar archivo existente para sobreescribir
                        var targetFile = targetFolder.findFile(fileName)

                        if (targetFile == null) {
                            // Crear archivo nuevo
                            targetFile = folderDocument.createFile(mimeType, fileName)
                        }

                        if (targetFile == null) {
                            result.error("CREATE_ERROR", "No se pudo crear el archivo: $fileName", null)
                            return@setMethodCallHandler
                        }

                        // Escribir contenido (modo truncate para sobreescribir)
                        contentResolver.openOutputStream(targetFile.uri, "wt")?.use { stream ->
                            stream.write(bytes)
                            stream.flush()
                        } ?: run {
                            result.error("WRITE_ERROR", "No se pudo abrir el stream de escritura", null)
                            return@setMethodCallHandler
                        }

                        result.success(targetFile.uri.toString())
                    } catch (e: Exception) {
                        result.error("WRITE_EXCEPTION", e.message, null)
                    }
                }

                /**
                 * Lee el contenido de un archivo dentro de una carpeta SAF.
                 *
                 * Argumentos: {
                 *   "folderUri": "content://...",
                 *   "fileName": "proyecto.json"
                 * }
                 * Retorna: ByteArray con el contenido del archivo
                 */
                "readFile" -> {
                    val folderUriStr = call.argument<String>("folderUri")
                    val fileName = call.argument<String>("fileName")

                    if (folderUriStr == null || fileName == null) {
                        result.error("INVALID_ARGS", "folderUri y fileName son requeridos", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val folderUri = Uri.parse(folderUriStr)
                        val folderDocument = androidx.documentfile.provider.DocumentFile
                            .fromTreeUri(applicationContext, folderUri)

                        val targetFolder = folderDocument?.findFile("INE")
                        if (targetFolder == null || !targetFolder.isDirectory) {
                            result.error("FILE_NOT_FOUND", "La carpeta INE no existe", null)
                            return@setMethodCallHandler
                        }

                        val targetFile = targetFolder.findFile(fileName)

                        if (targetFile == null || !targetFile.exists()) {
                            result.error("FILE_NOT_FOUND", "Archivo no encontrado: $fileName", null)
                            return@setMethodCallHandler
                        }

                        val bytes = contentResolver.openInputStream(targetFile.uri)?.use { stream ->
                            stream.readBytes()
                        } ?: run {
                            result.error("READ_ERROR", "No se pudo abrir el stream de lectura", null)
                            return@setMethodCallHandler
                        }

                        result.success(bytes)
                    } catch (e: Exception) {
                        result.error("READ_EXCEPTION", e.message, null)
                    }
                }

                /**
                 * Lista archivos JSON dentro de una carpeta SAF.
                 *
                 * Argumentos: { "folderUri": "content://..." }
                 * Retorna: List<Map<String,String>> con name, uri, size de cada archivo
                 */
                "listJsonFiles" -> {
                    val folderUriStr = call.argument<String>("folderUri")

                    if (folderUriStr == null) {
                        result.error("INVALID_ARGS", "folderUri es requerido", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val folderUri = Uri.parse(folderUriStr)
                        val folderDocument = androidx.documentfile.provider.DocumentFile
                            .fromTreeUri(applicationContext, folderUri)

                        val targetFolder = folderDocument?.findFile("INE")

                        val archivos = if (targetFolder != null && targetFolder.isDirectory) {
                            targetFolder.listFiles()
                                .filter { it.type == "application/json" || it.name?.endsWith(".json") == true }
                                .map { file ->
                                    mapOf(
                                        "name" to (file.name ?: ""),
                                        "uri" to file.uri.toString(),
                                        "size" to (file.length().toString())
                                    )
                                }
                        } else {
                            emptyList()
                        }

                        result.success(archivos)
                    } catch (e: Exception) {
                        result.error("LIST_EXCEPTION", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == DIRECTORY_REQUEST_CODE) {
            if (resultCode == android.app.Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                        pendingResult?.success(uri.toString())
                    } catch (e: Exception) {
                        pendingResult?.error("PERMISSION_ERROR", e.message, null)
                    }
                } else {
                    pendingResult?.error("NO_URI", "No se obtuvo URI", null)
                }
            } else {
                pendingResult?.error("CANCELLED", "El usuario canceló la selección", null)
            }
            pendingResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
