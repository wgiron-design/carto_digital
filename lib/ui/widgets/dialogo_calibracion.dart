import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/imagen_calibrada.dart';
import '../../../ui/theme/app_theme.dart';

/// Diálogo de calibración de imagen de fondo.
///
/// Permite al usuario ingresar las coordenadas WGS84 (Lat/Lng) de los
/// límites geográficos de la imagen (Norte, Sur, Este, Oeste) para
/// proyectarla correctamente como overlay sobre el mapa.
///
/// Flujo de uso:
/// 1. El usuario ya seleccionó un archivo de imagen (JPG/PNG)
/// 2. Este diálogo captura los 4 límites del bounding box
/// 3. Se retorna un objeto [ImagenCalibrada] con todos los parámetros
class DialogoCalibracion extends StatefulWidget {
  /// Ruta del archivo de imagen seleccionado previamente
  final String rutaImagen;

  /// Nombre sugerido para la imagen (puede editarse)
  final String nombreSugerido;

  /// Imagen existente para edición (si se está recalibrando)
  final ImagenCalibrada? imagenExistente;

  const DialogoCalibracion({
    super.key,
    required this.rutaImagen,
    required this.nombreSugerido,
    this.imagenExistente,
  });

  @override
  State<DialogoCalibracion> createState() => _DialogoCalibracionState();
}

class _DialogoCalibracionState extends State<DialogoCalibracion> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _norteCtrl;
  late final TextEditingController _surCtrl;
  late final TextEditingController _esteCtrl;
  late final TextEditingController _oesteCtrl;

  double _opacidad = 0.85;
  bool _previsualizando = false;

  @override
  void initState() {
    super.initState();
    final img = widget.imagenExistente;
    _nombreCtrl = TextEditingController(
        text: img?.nombre ?? widget.nombreSugerido);
    _norteCtrl = TextEditingController(
        text: img != null ? img.norte.toString() : '');
    _surCtrl = TextEditingController(
        text: img != null ? img.sur.toString() : '');
    _esteCtrl = TextEditingController(
        text: img != null ? img.este.toString() : '');
    _oesteCtrl = TextEditingController(
        text: img != null ? img.oeste.toString() : '');
    _opacidad = img?.opacidad ?? 0.85;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _norteCtrl.dispose();
    _surCtrl.dispose();
    _esteCtrl.dispose();
    _oesteCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final norte = double.parse(_norteCtrl.text.trim());
    final sur = double.parse(_surCtrl.text.trim());
    final este = double.parse(_esteCtrl.text.trim());
    final oeste = double.parse(_oesteCtrl.text.trim());

    final imagen = ImagenCalibrada(
      rutaArchivo: widget.rutaImagen,
      nombre: _nombreCtrl.text.trim(),
      norte: norte,
      sur: sur,
      este: este,
      oeste: oeste,
      opacidad: _opacidad,
    );

    if (!imagen.esValida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Los límites ingresados no son válidos. '
              'Verifica que Norte > Sur y que los valores estén en rango.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    Navigator.of(context).pop(imagen);
  }

  // Validador genérico de coordenada decimal
  String? _validarCoordenada(
      String? valor, double min, double max, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa la coordenada $campo';
    }
    final d = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (d == null) return 'Número inválido (usa punto decimal)';
    if (d < min || d > max) return '$campo debe estar entre $min y $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabecera ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.imagenExistente != null
                              ? 'Recalibrar Imagen'
                              : 'Calibrar Imagen de Fondo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Define los límites geográficos (WGS84)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(null),
                    color: AppTheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            ),

            // ── Contenido scrollable ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vista previa de la imagen
                      _buildImagePreview(),

                      const SizedBox(height: 20),

                      // Nombre
                      _buildTextField(
                        controller: _nombreCtrl,
                        label: 'Nombre de la imagen',
                        icon: Icons.image_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                      ),

                      const SizedBox(height: 20),

                      // Guía visual del bounding box
                      _buildBoundingBoxGuide(),

                      const SizedBox(height: 16),

                      // Coordenadas en layout de brújula
                      _buildCoordenadasGrid(),

                      const SizedBox(height: 20),

                      // Opacidad
                      _buildOpacidadSlider(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Botones ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Aplicar Calibración'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final file = File(widget.rutaImagen);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 140,
        color: AppTheme.surfaceVariant,
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _placeholderImagen(),
              )
            : _placeholderImagen(),
      ),
    );
  }

  Widget _placeholderImagen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined,
              size: 36, color: AppTheme.primary),
          const SizedBox(height: 6),
          Text(
            widget.nombreSugerido,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundingBoxGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ingresa las coordenadas decimales WGS84 de los 4 límites de la imagen.\n'
              'Norte y Sur son latitudes (−90 a 90).\n'
              'Este y Oeste son longitudes (−180 a 180).',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordenadasGrid() {
    return Column(
      children: [
        // NORTE — arriba centrado
        _buildCoordRow(
          controller: _norteCtrl,
          label: '⬆  Norte (Lat. máxima)',
          icon: Icons.north,
          color: const Color(0xFF4CAF50),
          validator: (v) => _validarCoordenada(v, -90, 90, 'Norte'),
          hint: 'ej. 15.5432',
        ),
        const SizedBox(height: 10),
        // OESTE y ESTE — lado a lado
        Row(
          children: [
            Expanded(
              child: _buildCoordRow(
                controller: _oesteCtrl,
                label: '◀  Oeste (Lng. mín.)',
                icon: Icons.west,
                color: const Color(0xFFFF9800),
                validator: (v) => _validarCoordenada(v, -180, 180, 'Oeste'),
                hint: 'ej. −88.3456',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCoordRow(
                controller: _esteCtrl,
                label: '▶  Este (Lng. máx.)',
                icon: Icons.east,
                color: const Color(0xFFFF9800),
                validator: (v) => _validarCoordenada(v, -180, 180, 'Este'),
                hint: 'ej. −88.1234',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // SUR — abajo centrado
        _buildCoordRow(
          controller: _surCtrl,
          label: '⬇  Sur (Lat. mínima)',
          icon: Icons.south,
          color: const Color(0xFF2196F3),
          validator: (v) => _validarCoordenada(v, -90, 90, 'Sur'),
          hint: 'ej. 15.4123',
        ),
      ],
    );
  }

  Widget _buildCoordRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required FormFieldValidator<String> validator,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
          signed: true, decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color, size: 18),
        labelStyle: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildOpacidadSlider() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.opacity, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Opacidad de la imagen',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(_opacidad * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _opacidad,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primary.withOpacity(0.2),
            onChanged: (v) => setState(() => _opacidad = v),
          ),
        ],
      ),
    );
  }
}
