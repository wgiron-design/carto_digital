import 'package:flutter/material.dart';
import 'nivel_service.dart';
import 'local_service.dart';
import 'hogar_service.dart';
import '../../ui/screens/nivel_form_screen.dart';
import '../../ui/screens/local_form_screen.dart';
import '../../ui/screens/hogar_form_screen.dart';

class JerarquiaNavigatorService {
  static final JerarquiaNavigatorService _instance = JerarquiaNavigatorService._internal();
  factory JerarquiaNavigatorService() => _instance;
  JerarquiaNavigatorService._internal();

  final _nivelService = NivelService();
  final _localService = LocalService();
  final _hogarService = HogarService();

  /// Acción "Siguiente / Guardar y Continuar" desde un Nivel
  Future<void> navegarSiguienteDesdeNivel({
    required BuildContext context,
    required String estructuraId,
    required String nombreEstructura,
    required String nivelId,
    required int numeroNivel,
    required int numeroLocalesEsperados,
  }) async {
    if (numeroLocalesEsperados > 0) {
      // Tiene locales.
      // Necesitamos ver si hay locales creados. Pero _localService.getLocalesByNivel falla si no existe `localesRegistrados`?
      // Ojo, asumimos que getLocalesByNivel existe en NivelService o LocalService
      final res = await _localService.getLocalesByNivel(nivelId);
      
      if (res.localesRegistrados == 0) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => LocalFormScreen(
                nivelId: nivelId,
                numeroNivel: numeroNivel,
                numeroLocalActual: 1,
                totalLocalesEsperados: numeroLocalesEsperados,
              ),
            ),
          );
        }
      } else {
        final primerLocal = res.locales.first;
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => LocalFormScreen(
                nivelId: nivelId,
                numeroNivel: numeroNivel,
                numeroLocalActual: 1,
                totalLocalesEsperados: numeroLocalesEsperados,
                localExistente: primerLocal,
              ),
            ),
          );
        }
      }
    } else {
      // Ir al siguiente nivel
      _navegarSiguienteNivel(context, estructuraId, nombreEstructura, numeroNivel);
    }
  }

  /// Acción "Siguiente / Guardar y Continuar" desde un Local
  Future<void> navegarSiguienteDesdeLocal({
    required BuildContext context,
    required String estructuraId,
    required String nombreEstructura,
    required String nivelId,
    required int numeroNivel,
    required String localId,
    required String nombreLocal,
    required int numeroLocalActual,
    required int totalLocalesEsperados,
    required int? numeroHogaresEsperados,
  }) async {
    if (numeroHogaresEsperados != null && numeroHogaresEsperados > 0) {
      final resHogares = await _hogarService.getHogaresByLocal(localId);
      if (resHogares.hogaresRegistrados < numeroHogaresEsperados) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => HogarFormScreen(
                localId: localId,
                nombreLocal: nombreLocal,
                numeroNivel: numeroNivel,
                numeroHogarActual: resHogares.hogaresRegistrados + 1,
                totalHogaresEsperados: numeroHogaresEsperados,
              ),
            ),
          );
        }
        return;
      }
    }
    
    // Ir al siguiente Local
    if (numeroLocalActual < totalLocalesEsperados) {
      final resLocales = await _localService.getLocalesByNivel(nivelId);
      final indexSiguiente = numeroLocalActual;
      
      if (indexSiguiente < resLocales.locales.length) {
        final localSig = resLocales.locales[indexSiguiente];
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => LocalFormScreen(
                nivelId: nivelId,
                numeroNivel: numeroNivel,
                numeroLocalActual: numeroLocalActual + 1,
                totalLocalesEsperados: totalLocalesEsperados,
                localExistente: localSig,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => LocalFormScreen(
                nivelId: nivelId,
                numeroNivel: numeroNivel,
                numeroLocalActual: numeroLocalActual + 1,
                totalLocalesEsperados: totalLocalesEsperados,
              ),
            ),
          );
        }
      }
    } else {
      _navegarSiguienteNivel(context, estructuraId, nombreEstructura, numeroNivel);
    }
  }

  /// Acción "Siguiente / Guardar y Continuar" desde un Hogar
  Future<void> navegarSiguienteDesdeHogar({
    required BuildContext context,
    required String estructuraId,
    required String nombreEstructura,
    required String nivelId,
    required int numeroNivel,
    required String localId,
    required int numeroLocalActual,
    required int totalLocalesEsperados,
    required int numeroHogarActual,
    required int totalHogaresEsperados,
  }) async {
    if (numeroHogarActual < totalHogaresEsperados) {
      final resHogares = await _hogarService.getHogaresByLocal(localId);
      final indexSiguiente = numeroHogarActual;
      
      if (indexSiguiente < resHogares.hogares.length) {
        final hogarSig = resHogares.hogares[indexSiguiente];
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => HogarFormScreen(
                localId: localId,
                nombreLocal: resHogares.nombreLocal ?? '',
                numeroNivel: numeroNivel,
                numeroHogarActual: numeroHogarActual + 1,
                totalHogaresEsperados: totalHogaresEsperados,
                hogarExistente: hogarSig,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => HogarFormScreen(
                localId: localId,
                nombreLocal: resHogares.nombreLocal ?? '',
                numeroNivel: numeroNivel,
                numeroHogarActual: numeroHogarActual + 1,
                totalHogaresEsperados: totalHogaresEsperados,
              ),
            ),
          );
        }
      }
    } else {
      // Volver a calcular Siguiente Local
      final resLocales = await _localService.getLocalesByNivel(nivelId);
      if (numeroLocalActual < totalLocalesEsperados) {
        final indexSiguienteLocal = numeroLocalActual;
        if (indexSiguienteLocal < resLocales.locales.length) {
          final localSig = resLocales.locales[indexSiguienteLocal];
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (c) => LocalFormScreen(
                  nivelId: nivelId,
                  numeroNivel: numeroNivel,
                  numeroLocalActual: numeroLocalActual + 1,
                  totalLocalesEsperados: totalLocalesEsperados,
                  localExistente: localSig,
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (c) => LocalFormScreen(
                  nivelId: nivelId,
                  numeroNivel: numeroNivel,
                  numeroLocalActual: numeroLocalActual + 1,
                  totalLocalesEsperados: totalLocalesEsperados,
                ),
              ),
            );
          }
        }
      } else {
        _navegarSiguienteNivel(context, estructuraId, nombreEstructura, numeroNivel);
      }
    }
  }

  Future<void> _navegarSiguienteNivel(BuildContext context, String estructuraId, String nombreEstructura, int numeroNivel) async {
    // Para simplificar, hacemos pop() al llegar al final y que vuelvan al mapa o jerarquia.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado correctamente. Has completado esta rama de la jerarquía.')),
      );
      Navigator.pop(context, true); 
    }
  }
}
