import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/breadcrumb_bar.dart';
import '../../core/services/nivel_service.dart';

class NivelFormScreen extends StatefulWidget {
  final String estructuraId;
  final String nombreEstructura;
  final int nivelesCantidad;
  final NivelResumen? nivelExistente;
  final int totalNiveles;
  final int nivelIndexActual;

  const NivelFormScreen({
    super.key,
    required this.estructuraId,
    required this.nombreEstructura,
    required this.nivelesCantidad,
    this.nivelExistente,
    required this.totalNiveles,
    required this.nivelIndexActual,
  });

  @override
  State<NivelFormScreen> createState() => _NivelFormScreenState();
}

class _NivelFormScreenState extends State<NivelFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _numeroLocales;
  late TextEditingController _descripcionCtrl;
  bool _isSaving = false;

  Map<String, dynamic>? _conflictData;

  @override
  void initState() {
    super.initState();
    _numeroLocales = widget.nivelExistente?.numeroLocales ?? 1;
    _descripcionCtrl = TextEditingController(text: widget.nivelExistente?.descripcion ?? '');
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _conflictData = null;
    });

    try {
      if (widget.nivelExistente == null) {
        // Crear
        await NivelService().crearNivel(
          widget.estructuraId,
          numeroLocales: _numeroLocales,
          descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        );
      } else {
        // Editar
        await NivelService().editarNivel(
          widget.nivelExistente!.id,
          numeroLocales: _numeroLocales,
          descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nivel guardado correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on NivelApiException catch (e) {
      if (e.code == 'perdida_de_datos_local') {
        setState(() {
          _conflictData = e.data;
        });
      } else {
        _mostrarErrorSnackBar(e.message);
      }
    } catch (e) {
      _mostrarErrorSnackBar('No se pudo guardar el nivel. Revisa la conexión.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmarEliminacionYGuardar() async {
    if (widget.nivelExistente == null || _conflictData == null) return;

    setState(() => _isSaving = true);
    try {
      await NivelService().confirmarEliminacionLocales(
        widget.nivelExistente!.id,
        _numeroLocales,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Locales actualizados correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on NivelApiException catch (e) {
      _mostrarErrorSnackBar(e.message);
    } catch (e) {
      _mostrarErrorSnackBar('Error de conexión al eliminar locales excedentes');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mantenerValorOriginal() {
    setState(() {
      _numeroLocales = widget.nivelExistente?.numeroLocales ?? 1;
      _conflictData = null;
    });
  }

  void _mostrarErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _guardar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.nivelExistente != null;
    final int numeroMostrar = isEditing
        ? widget.nivelExistente!.numero
        : widget.nivelIndexActual + 1;

    final charCount = _descripcionCtrl.text.length;

    Color charCounterColor = AppTheme.onSurface.withOpacity(0.5);
    if (charCount >= 46 && charCount < 50) {
      charCounterColor = AppTheme.warning;
    } else if (charCount == 50) {
      charCounterColor = AppTheme.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Nivel $numeroMostrar' : 'Nuevo Nivel'),
      ),
      body: Column(
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(label: widget.nombreEstructura, onTap: () => Navigator.pop(context)),
              BreadcrumbItem(label: 'Niveles', onTap: () => Navigator.pop(context)),
              BreadcrumbItem(label: isEditing ? 'Editar Nivel $numeroMostrar' : 'Crear Nivel'),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper de Número de Nivel (DESHABILITADO)
                    const Text(
                      'Número de Nivel / Piso',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Opacity(
                            opacity: 0.35,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: null,
                            ),
                          ),
                          Text(
                            'Nivel $numeroMostrar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Opacity(
                            opacity: 0.35,
                            child: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, bottom: 20),
                      child: Text(
                        'El número de nivel lo asigna el sistema automáticamente.',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurface.withOpacity(0.5)),
                      ),
                    ),

                    // Stepper de Cantidad de Locales (HABILITADO)
                    const Text(
                      'Cantidad de Locales (Esperados)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppTheme.primary),
                            onPressed: _numeroLocales > 1
                                ? () => setState(() => _numeroLocales--)
                                : null,
                          ),
                          Text(
                            '$_numeroLocales locales',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                            onPressed: () => setState(() => _numeroLocales++),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, bottom: 20),
                      child: Text(
                        'Define cuántos locales o viviendas contiene este nivel.',
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurface.withOpacity(0.5)),
                      ),
                    ),

                    // Banner de Advertencia de Pérdida de Datos (Conflicto 409)
                    if (_conflictData != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.15),
                          border: Border.all(color: AppTheme.error, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                                SizedBox(width: 8),
                                Text(
                                  'Advertencia de Pérdida de Datos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.error,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reducir a $_numeroLocales locales eliminará ${_conflictData!['locales_afectados']} local(es), ${_conflictData!['hogares_afectados']} hogar(es) y ${_conflictData!['personas_afectadas']} persona(s).',
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.error,
                                      side: const BorderSide(color: AppTheme.error),
                                    ),
                                    onPressed: _isSaving ? null : _confirmarEliminacionYGuardar,
                                    child: const Text('Eliminar y continuar', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                    ),
                                    onPressed: _isSaving ? null : _mantenerValorOriginal,
                                    child: Text(
                                      'Mantener en ${widget.nivelExistente?.numeroLocales}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Input de Descripción
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLength: 50,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Descripción / Nota corta (Opcional)',
                        hintText: 'Ej. Planta Baja, Deptos 101-104...',
                        counterText: '$charCount/50',
                        counterStyle: TextStyle(color: charCounterColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003731)),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                  onPressed: (_isSaving || _conflictData != null) ? null : _guardar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
