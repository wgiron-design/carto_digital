import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/capa_geometrica.dart';
import '../../core/models/jerarquia.dart';
import '../../core/controllers/digitalizacion_controller.dart';
import '../theme/app_theme.dart';
import 'navegador_formulario_screen.dart';
import '../widgets/dialogos_jerarquia.dart';

class JerarquiaScreen extends StatefulWidget {
  final PuntoEstructura puntoInicial;

  const JerarquiaScreen({super.key, required this.puntoInicial});

  @override
  State<JerarquiaScreen> createState() => _JerarquiaScreenState();
}

class _JerarquiaScreenState extends State<JerarquiaScreen> {
  late PuntoEstructura _punto;
  bool _canPop = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _punto = widget.puntoInicial;
  }

  void _intentarSalir() async {
    if (!_isDirty) {
      _popConExito();
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Ha realizado modificaciones en la jerarquía. ¿Qué desea hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'save'),
            child: const Text('Guardar', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (action == 'discard') {
      _popConExito();
    } else if (action == 'save') {
      _guardarYSalirDirecto();
    }
  }

  void _guardarYSalirDirecto() async {
    if (_punto.niveles.length != _punto.nivelesCantidad) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Advertencia de Niveles'),
          content: Text('El número de niveles declarado en la estructura es de ${_punto.nivelesCantidad} y el número de registros de la tabla niveles es de ${_punto.niveles.length}. ¿Desea guardar de todos modos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Revisar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Guardar y Salir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (mounted) {
      context.read<DigitalizacionController>().actualizarPunto(_punto);
      _popConExito();
    }
  }

  void _popConExito() {
    setState(() => _canPop = true);
    Future.microtask(() {
      if (mounted) Navigator.pop(context);
    });
  }

  String get _idEstructura => _punto.id;

  // ─────────────────────────────────────────────────────────────────────────────
  // ACCIONES DE NIVEL
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _addNivel() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => DialogoNuevoNivel(nivelSugerido: _punto.niveles.length + 1),
    );
    if (resultado != null) {
      final numero = resultado['numero'] as int;
      final locales = resultado['locales'] as int;
      final n = Nivel.nuevo(idEstructura: _idEstructura, numeroNivel: numero, numeroLocales: locales);
      setState(() {
        _punto = _punto.copyWith(niveles: [..._punto.niveles, n]);
        _isDirty = true;
      });
    }
  }

  void _deleteNivel(String idNivel) {
    setState(() {
      final list = List<Nivel>.from(_punto.niveles)..removeWhere((n) => n.id == idNivel);
      _punto = _punto.copyWith(niveles: list);
      _isDirty = true;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ACCIONES DE LOCAL
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _addLocal(Nivel nivel) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => DialogoNuevoLocal(localSugerido: nivel.locales.length + 1),
    );
    if (resultado != null) {
      final int numero = resultado['numero'];
      final String usoActual = resultado['uso_actual'];
      final String? ocupacion = resultado['ocupacion'];
      final int? numeroHogares = resultado['numero_hogares'];
      final local = Local.nuevo(
        idNivel: nivel.id, 
        nombre: 'Local $numero', 
        usoActual: usoActual,
        ocupacion: ocupacion,
        numeroHogares: numeroHogares,
      );
      _updateNivel(nivel.copyWith(locales: [...nivel.locales, local]));
    }
  }

  void _deleteLocal(Nivel nivel, String idLocal) {
    final list = List<Local>.from(nivel.locales)..removeWhere((l) => l.id == idLocal);
    _updateNivel(nivel.copyWith(locales: list));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ACCIONES DE HOGAR
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _addHogar(Nivel nivel, Local local) async {
    final Map<String, dynamic>? resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => DialogoNuevoHogar(hogarSugerido: local.hogares.length + 1),
    );
    if (resultado != null) {
      final int numero = resultado['numero'];
      final String jefeFamilia = resultado['jefe_familia'];
      final String? sexoJefe = resultado['sexo_jefe'];
      
      final hogar = Hogar.nuevo(
        idLocal: local.id, 
        jefeFamilia: jefeFamilia,
        sexoJefe: sexoJefe,
      );
      final newLocal = local.copyWith(hogares: [...local.hogares, hogar]);
      _updateLocal(nivel, newLocal);
    }
  }

  void _deleteHogar(Nivel nivel, Local local, String idHogar) {
    final list = List<Hogar>.from(local.hogares)..removeWhere((h) => h.id == idHogar);
    _updateLocal(nivel, local.copyWith(hogares: list));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  void _updateNivel(Nivel updated) {
    setState(() {
      final index = _punto.niveles.indexWhere((n) => n.id == updated.id);
      if (index != -1) {
        final list = List<Nivel>.from(_punto.niveles);
        list[index] = updated;
        _punto = _punto.copyWith(niveles: list);
        _isDirty = true;
      }
    });
  }

  void _updateLocal(Nivel nivel, Local updatedLocal) {
    final index = nivel.locales.indexWhere((l) => l.id == updatedLocal.id);
    if (index != -1) {
      final list = List<Local>.from(nivel.locales);
      list[index] = updatedLocal;
      _updateNivel(nivel.copyWith(locales: list));
    }
  }

  Future<void> _abrirNavegador({
    required TipoJerarquia tipo,
    required int nivelIndex,
    int? localIndex,
    int? hogarIndex,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavegadorFormularioScreen(
          punto: _punto,
          tipo: tipo,
          nivelIndex: nivelIndex,
          localIndex: localIndex,
          hogarIndex: hogarIndex,
          onGuardar: (PuntoEstructura updated) {
            setState(() {
              _punto = updated;
              _isDirty = true;
            });
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI BUILDERS
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _intentarSalir();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: BackButton(onPressed: _intentarSalir),
          title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jerarquía de Estructura'),
            Text(
              '${_punto.nombre} - ${_punto.labelTipoActivo} | ${_punto.nivelesCantidad} niveles',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar y salir',
            onPressed: _guardarYSalirDirecto,
          ),
        ],
      ),
      body: _punto.niveles.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 64, color: AppTheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Sin niveles asignados', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addNivel,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Primer Nivel'),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _punto.niveles.length,
              itemBuilder: (context, index) {
                final nivel = _punto.niveles[index];
                return _buildCardNivel(index, nivel);
              },
            ),
      floatingActionButton: _punto.niveles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addNivel,
              icon: const Icon(Icons.add),
              label: const Text('Nivel'),
              backgroundColor: AppTheme.primary,
            )
          : null,
      ),
    );
  }

  Widget _buildCardNivel(int nivelIndex, Nivel nivel) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: AppTheme.primary,
        iconColor: AppTheme.primary,
        title: Row(
          children: [
            const Icon(Icons.layers, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text('Nivel ${nivel.numeroNivel}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text('${nivel.totalLocales} de ${nivel.numeroLocales} locales registrados · ${nivel.totalHogares} hogares', style: const TextStyle(fontSize: 12)),
        trailing: Wrap(
          spacing: -8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              tooltip: 'Editar Nivel',
              onPressed: () => _abrirNavegador(
                tipo: TipoJerarquia.nivel,
                nivelIndex: nivelIndex,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_business, color: AppTheme.secondary),
              tooltip: 'Añadir Local',
              onPressed: () => _addLocal(nivel),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Eliminar Nivel',
              onPressed: () => _deleteNivel(nivel.id),
            ),
          ],
        ),
        children: nivel.locales.asMap().entries.map((e) => _buildCardLocal(nivelIndex, e.key, nivel, e.value)).toList(),
      ),
    );
  }

  Widget _buildCardLocal(int nivelIndex, int localIndex, Nivel nivel, Local local) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        iconColor: AppTheme.secondary,
        collapsedIconColor: AppTheme.secondary,
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppTheme.secondary, size: 18),
            const SizedBox(width: 8),
            Text(local.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (local.numeroHogares != null && local.numeroHogares != local.hogares.length && 
                (local.ocupacion?.contains('habitantes presentes') == true || local.ocupacion?.contains('habitantes ausentes') == true)) ...[
              const SizedBox(width: 8),
              const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
            ]
          ],
        ),
        subtitle: Text(
          '${local.usoActual}' + (local.numeroHogares != null ? ' • ${local.hogares.length} de ${local.numeroHogares} hogares' : ' • ${local.totalHogares} hogares (sub-locales)'),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Wrap(
          spacing: -8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.secondary, size: 18),
              tooltip: 'Editar Local',
              onPressed: () => _abrirNavegador(
                tipo: TipoJerarquia.local,
                nivelIndex: nivelIndex,
                localIndex: localIndex,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.group_add, color: AppTheme.tertiary, size: 18),
              tooltip: 'Añadir Hogar',
              onPressed: () => _addHogar(nivel, local),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
              tooltip: 'Eliminar Local',
              onPressed: () => _deleteLocal(nivel, local.id),
            ),
          ],
        ),
        children: local.hogares.asMap().entries.map((e) => _buildItemHogar(nivelIndex, localIndex, e.key, nivel, local, e.value)).toList(),
      ),
    );
  }

  Widget _buildItemHogar(int nivelIndex, int localIndex, int hogarIndex, Nivel nivel, Local local, Hogar hogar) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 12, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.tertiary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppTheme.tertiary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(hogar.jefeFamilia, style: const TextStyle(fontSize: 13))),
          InkWell(
            onTap: () => _abrirNavegador(
              tipo: TipoJerarquia.hogar,
              nivelIndex: nivelIndex,
              localIndex: localIndex,
              hogarIndex: hogarIndex,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.edit, color: AppTheme.tertiary, size: 16),
            ),
          ),
          InkWell(
            onTap: () => _deleteHogar(nivel, local, hogar.id),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close, color: AppTheme.error, size: 16),
            ),
          )
        ],
      ),
    );
  }
}
