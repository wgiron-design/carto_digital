import 'package:flutter/material.dart';
import '../../core/models/capa_geometrica.dart';
import '../../ui/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TIPOS DE RETORNO (DART 3 RECORDS)
// ─────────────────────────────────────────────────────────────────────────────

typedef AtributosPuntoResult = ({
  String nombre,
  CategoriaEstructura categoria,
  TipoEstructuraFormal? tipoFormal,
  TipoEstructuraReferencia? tipoReferencia,
  EstadoEstructura estado,
  int nivelesCantidad,
  String notas,
});

typedef AtributosLineaResult = ({
  String nombre,
  TipoCamino tipo,
  String notas,
});

typedef AtributosPoligonoResult = ({
  String nombre,
  String codigoUPM,
  String notas,
});

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO DE ATRIBUTOS — PUNTO / ESTRUCTURA
// ─────────────────────────────────────────────────────────────────────────────

/// Formulario de atributos para un nuevo punto (Estructura) o para editar uno existente.
/// El Paso 4 extenderá esto con la gestión de Niveles/Locales/Sub-locales.
class DialogoAtributosPunto extends StatefulWidget {
  final double lat;
  final double lng;

  // Parámetros opcionales para modo edición / consulta
  final String? nombreInicial;
  final CategoriaEstructura? categoriaInicial;
  final TipoEstructuraFormal? tipoFormalInicial;
  final TipoEstructuraReferencia? tipoReferenciaInicial;
  final EstadoEstructura? estadoInicial;
  final int? nivelesInicial;
  final String? notasIniciales;
  final bool soloLectura;

  const DialogoAtributosPunto({
    super.key,
    required this.lat,
    required this.lng,
    this.nombreInicial,
    this.categoriaInicial,
    this.tipoFormalInicial,
    this.tipoReferenciaInicial,
    this.estadoInicial,
    this.nivelesInicial,
    this.notasIniciales,
    this.soloLectura = false,
  });

  bool get esModoEdicion => nombreInicial != null;

  @override
  State<DialogoAtributosPunto> createState() => _DialogoAtributosPuntoState();
}

class _DialogoAtributosPuntoState extends State<DialogoAtributosPunto> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _notasCtrl;
  
  late CategoriaEstructura _categoria;
  late TipoEstructuraFormal? _tipoFormal;
  late TipoEstructuraReferencia? _tipoReferencia;
  late EstadoEstructura _estado;
  late int _niveles;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreInicial ?? '');
    _notasCtrl = TextEditingController(text: widget.notasIniciales ?? '');
    _categoria = widget.categoriaInicial ?? CategoriaEstructura.formal;
    _tipoFormal = widget.tipoFormalInicial ?? TipoEstructuraFormal.vivienda;
    _tipoReferencia = widget.tipoReferenciaInicial ?? TipoEstructuraReferencia.puente;
    _estado = widget.estadoInicial ?? EstadoEstructura.presente;
    _niveles = widget.nivelesInicial ?? 1;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esModoEdicion = widget.esModoEdicion;
    final soloLectura = widget.soloLectura;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(
              icon: soloLectura 
                  ? Icons.info_outline 
                  : (esModoEdicion ? Icons.edit_location_alt : Icons.place),
              titulo: soloLectura 
                  ? 'Atributos de Estructura' 
                  : (esModoEdicion ? 'Editar Estructura' : 'Nueva Estructura'),
              subtitulo:
                  'Lat: ${widget.lat.toStringAsFixed(6)}  '
                  'Lng: ${widget.lng.toStringAsFixed(6)}',
              color: soloLectura 
                  ? const Color(0xFF4FC3F7) 
                  : (esModoEdicion ? const Color(0xFFFFB74D) : const Color(0xFF4FC3F7)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreCtrl,
                      autofocus: !soloLectura,
                      readOnly: soloLectura,
                      decoration: const InputDecoration(
                        labelText: 'Nombre / Identificador *',
                        hintText: 'ej. Casa 001, Comercio Norte...',
                        prefixIcon: Icon(Icons.label_outline, size: 18),
                      ),
                      validator: (v) =>
                          (!soloLectura && (v == null || v.trim().isEmpty)) ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 14),

                    // Categoría
                    Text('Categoría de Estructura', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<CategoriaEstructura>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Formal', style: TextStyle(fontSize: 14)),
                            value: CategoriaEstructura.formal,
                            groupValue: _categoria,
                            onChanged: soloLectura ? null : (v) => setState(() => _categoria = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<CategoriaEstructura>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Referencia Geográfica', style: TextStyle(fontSize: 14)),
                            value: CategoriaEstructura.referencia,
                            groupValue: _categoria,
                            onChanged: soloLectura ? null : (v) => setState(() => _categoria = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Tipo
                    Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    if (_categoria == CategoriaEstructura.formal)
                      DropdownButtonFormField<TipoEstructuraFormal>(
                        value: _tipoFormal,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.category, size: 18)),
                        items: TipoEstructuraFormal.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          );
                        }).toList(),
                        onChanged: soloLectura ? null : (v) => setState(() => _tipoFormal = v),
                      )
                    else
                      DropdownButtonFormField<TipoEstructuraReferencia>(
                        value: _tipoReferencia,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.category, size: 18)),
                        items: TipoEstructuraReferencia.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          );
                        }).toList(),
                        onChanged: soloLectura ? null : (v) => setState(() => _tipoReferencia = v),
                      ),

                    const SizedBox(height: 14),

                    // Estado y Niveles
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estado', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<EstadoEstructura>(
                                value: _estado,
                                items: EstadoEstructura.values.map((e) {
                                  return DropdownMenuItem(value: e, child: Text(e.label, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: soloLectura ? null : (v) => setState(() => _estado = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Niveles (1-10)', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _niveles,
                                items: List.generate(10, (i) => i + 1).map((n) {
                                  return DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: soloLectura ? null : (v) => setState(() => _niveles = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notas
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 2,
                      readOnly: soloLectura,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                    ),

                    if (!esModoEdicion && !soloLectura) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💡 En el Paso 4 podrás agregar Niveles, Locales y Sub-locales a esta estructura.',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(
              onCancelar: () => Navigator.pop(context, null),
              onConfirmar: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  nombre: _nombreCtrl.text.trim(),
                  categoria: _categoria,
                  tipoFormal: _tipoFormal,
                  tipoReferencia: _tipoReferencia,
                  estado: _estado,
                  nivelesCantidad: _niveles,
                  notas: _notasCtrl.text.trim(),
                ) as AtributosPuntoResult);
              },
              labelConfirmar: esModoEdicion ? 'Guardar Cambios' : 'Crear Estructura',
              soloLectura: soloLectura,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO DE ATRIBUTOS — LÍNEA / CAMINO
// ─────────────────────────────────────────────────────────────────────────────

class DialogoAtributosLinea extends StatefulWidget {
  final int numVertices;
  final double longitudM;
  final String? nombreInicial;
  final TipoCamino? tipoInicial;
  final bool soloLectura;

  const DialogoAtributosLinea({
    super.key,
    required this.numVertices,
    required this.longitudM,
    this.nombreInicial,
    this.tipoInicial,
    this.soloLectura = false,
  });

  bool get esModoEdicion => nombreInicial != null;

  @override
  State<DialogoAtributosLinea> createState() => _DialogoAtributosLineaState();
}

class _DialogoAtributosLineaState extends State<DialogoAtributosLinea> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  TipoCamino? _tipo;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl = TextEditingController(text: widget.nombreInicial);
    _tipo = widget.tipoInicial;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soloLectura = widget.soloLectura;
    final esModoEdicion = widget.esModoEdicion;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(
              icon: soloLectura ? Icons.info_outline : Icons.polyline,
              titulo: soloLectura 
                  ? 'Atributos de Línea / Camino' 
                  : (esModoEdicion ? 'Editar Línea / Camino' : 'Nueva Línea / Camino'),
              subtitulo:
                  '${widget.numVertices} vértices · '
                  '${(widget.longitudM / 1000).toStringAsFixed(3)} km',
              color: const Color(0xFFFFB74D),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Dirección / Descripción (multilínea) ──
                    TextFormField(
                      controller: _descripcionCtrl,
                      autofocus: !soloLectura,
                      readOnly: soloLectura,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección / Descripción',
                        hintText: 'ej. Camino principal hacia la escuela,\nAcceso norte, Entrada al caserío...',
                        prefixIcon: Icon(Icons.description_outlined, size: 18),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Tipo de Camino (ComboBox obligatorio) ──
                    DropdownButtonFormField<TipoCamino>(
                      value: _tipo,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Camino *',
                        prefixIcon: Icon(Icons.route_outlined, size: 18),
                      ),
                      items: TipoCamino.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text('${t.simbolo}  ${t.label}'),
                        );
                      }).toList(),
                      onChanged: soloLectura ? null : (v) => setState(() => _tipo = v),
                      validator: (v) =>
                          (!soloLectura && v == null) ? 'Seleccione un tipo de camino' : null,
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(
              onCancelar: () => Navigator.pop(context, null),
              onConfirmar: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  nombre: _descripcionCtrl.text.trim(),
                  tipo: _tipo!,
                  notas: '',
                ) as AtributosLineaResult);
              },
              labelConfirmar: esModoEdicion ? 'Guardar Cambios' : 'Guardar Línea',
              soloLectura: soloLectura,
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO DE ATRIBUTOS — POLÍGONO / UPM
// ─────────────────────────────────────────────────────────────────────────────

class DialogoAtributosPoligono extends StatefulWidget {
  final int numVertices;
  final double areaMCuad;
  final String? nombreInicial;
  final String? codigoUPMInicial;
  final bool soloLectura;

  const DialogoAtributosPoligono({
    super.key,
    required this.numVertices,
    required this.areaMCuad,
    this.nombreInicial,
    this.codigoUPMInicial,
    this.soloLectura = false,
  });

  bool get esModoEdicion => nombreInicial != null;

  @override
  State<DialogoAtributosPoligono> createState() =>
      _DialogoAtributosPoligonoState();
}

class _DialogoAtributosPoligonoState extends State<DialogoAtributosPoligono> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _codigoCtrl;
  final _notasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreInicial ?? '');
    _codigoCtrl = TextEditingController(text: widget.codigoUPMInicial ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areaHa = widget.areaMCuad / 10000;
    final soloLectura = widget.soloLectura;
    final esModoEdicion = widget.esModoEdicion;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(
              icon: soloLectura ? Icons.info_outline : Icons.pentagon,
              titulo: soloLectura 
                  ? 'Atributos de UPM' 
                  : (esModoEdicion ? 'Editar UPM' : 'Nueva UPM'),
              subtitulo:
                  '${widget.numVertices} vértices · '
                  '${areaHa.toStringAsFixed(4)} ha',
              color: const Color(0xFFA5D6A7),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      autofocus: !soloLectura,
                      readOnly: soloLectura,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la UPM *',
                        hintText: 'ej. UPM-001, Sector Norte...',
                        prefixIcon: Icon(Icons.label_outline, size: 18),
                      ),
                      validator: (v) =>
                          (!soloLectura && (v == null || v.trim().isEmpty)) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _codigoCtrl,
                      readOnly: soloLectura,
                      decoration: const InputDecoration(
                        labelText: 'Código UPM (opcional)',
                        hintText: 'ej. 01-02-003',
                        prefixIcon: Icon(Icons.qr_code, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 2,
                      readOnly: soloLectura,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(
              onCancelar: () => Navigator.pop(context, null),
              onConfirmar: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  nombre: _nombreCtrl.text.trim(),
                  codigoUPM: _codigoCtrl.text.trim(),
                  notas: _notasCtrl.text.trim(),
                ) as AtributosPoligonoResult);
              },
              labelConfirmar: esModoEdicion ? 'Guardar Cambios' : 'Guardar UPM',
              soloLectura: soloLectura,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPARTIDOS ENTRE DIÁLOGOS
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildHeader({
  required IconData icon,
  required String titulo,
  required String subtitulo,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariant,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      border: Border(bottom: BorderSide(color: color.withOpacity(0.3), width: 1)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitulo,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFooter({
  required VoidCallback onCancelar,
  required VoidCallback onConfirmar,
  required String labelConfirmar,
  bool soloLectura = false,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    decoration: const BoxDecoration(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
    ),
    child: soloLectura
        ? SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancelar,
              child: const Text('Cerrar'),
            ),
          )
        : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancelar,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirmar,
                  child: Text(labelConfirmar),
                ),
              ),
            ],
          ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────


class _ChipSelector extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final Color color;
  final VoidCallback onTap;

  const _ChipSelector({
    required this.label,
    required this.seleccionado,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.15) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? color : const Color(0xFF2D4054),
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? color : AppTheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight:
                seleccionado ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
