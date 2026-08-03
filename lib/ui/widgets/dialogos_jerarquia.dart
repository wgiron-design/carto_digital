import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO: NUEVO NIVEL
// ─────────────────────────────────────────────────────────────────────────────

class DialogoNuevoNivel extends StatefulWidget {
  final int nivelSugerido;

  const DialogoNuevoNivel({super.key, required this.nivelSugerido});

  @override
  State<DialogoNuevoNivel> createState() => _DialogoNuevoNivelState();
}

class _DialogoNuevoNivelState extends State<DialogoNuevoNivel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroCtrl;
  int _numeroLocales = 1;

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(text: widget.nivelSugerido.toString());
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.layers, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Text('Añadir Nivel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _numeroCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Número de Nivel / Piso',
                        hintText: 'Ej. 1, 2, 3...',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Debe ser número';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _numeroLocales,
                      decoration: const InputDecoration(labelText: 'Cantidad de Locales'),
                      items: List.generate(15, (i) => i + 1).map((n) {
                        return DropdownMenuItem(value: n, child: Text(n.toString()));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _numeroLocales = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'numero': int.parse(_numeroCtrl.text),
                          'locales': _numeroLocales
                        });
                      }
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO: NUEVO LOCAL
// ─────────────────────────────────────────────────────────────────────────────

class DialogoNuevoLocal extends StatefulWidget {
  final int localSugerido;

  const DialogoNuevoLocal({super.key, required this.localSugerido});

  @override
  State<DialogoNuevoLocal> createState() => _DialogoNuevoLocalState();
}

class _DialogoNuevoLocalState extends State<DialogoNuevoLocal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroCtrl;
  String? _usoActual;
  String? _ocupacion;
  final TextEditingController _numeroHogaresCtrl = TextEditingController();

  final List<String> _opcionesUso = [
    'Locales de habitación',
    'Habitación y comercio',
    'Comercial',
    'Institución pública o privada',
    'Local en construcción'
  ];

  final List<String> _opcionesOcupacion = [
    'Vivienda con habitantes presentes (con entrevista efectiva)',
    'Vivienda con habitantes ausentes (al momento de la visita)',
    'Vivienda de ocupación temporal (vacacional, de temporada, o alquiler)',
    'Vivienda desocupada (en venta o abandono)',
    'Rechazo (negativa de los informantes a proporcionar datos)'
  ];

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(text: widget.localSugerido.toString());
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _numeroHogaresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront, color: AppTheme.secondary),
                  SizedBox(width: 12),
                  Text('Añadir Local', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _numeroCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Número de Local / Vivienda',
                        hintText: 'Ej. 101, 102...',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Debe ser número';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Uso actual *'),
                      value: _usoActual,
                      items: _opcionesUso.map((uso) {
                        return DropdownMenuItem(value: uso, child: Text(uso, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _usoActual = v;
                          if (_usoActual != 'Locales de habitación' && _usoActual != 'Habitación y comercio') {
                            _ocupacion = null;
                          }
                        });
                      },
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    if (_usoActual == 'Locales de habitación' || _usoActual == 'Habitación y comercio') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ocupación *'),
                        value: _ocupacion,
                        items: _opcionesOcupacion.map((oc) {
                          return DropdownMenuItem(value: oc, child: Text(oc, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (v) => setState(() => _ocupacion = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      if (_ocupacion == 'Vivienda con habitantes presentes (con entrevista efectiva)' || 
                          _ocupacion == 'Vivienda con habitantes ausentes (al momento de la visita)') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _numeroHogaresCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Número de Hogares *',
                            hintText: 'Ej. 1, 2...',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (int.tryParse(v) == null) return 'Debe ser número';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'numero': int.parse(_numeroCtrl.text),
                          'uso_actual': _usoActual!,
                          'ocupacion': _ocupacion,
                          'numero_hogares': (_usoActual == 'Locales de habitación' || _usoActual == 'Habitación y comercio') && 
                                            (_ocupacion == 'Vivienda con habitantes presentes (con entrevista efectiva)' || 
                                             _ocupacion == 'Vivienda con habitantes ausentes (al momento de la visita)')
                              ? int.parse(_numeroHogaresCtrl.text)
                              : null,
                        });
                      }
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO: NUEVO HOGAR (SUB-LOCAL)
// ─────────────────────────────────────────────────────────────────────────────

class DialogoNuevoHogar extends StatefulWidget {
  final int hogarSugerido;

  const DialogoNuevoHogar({super.key, required this.hogarSugerido});

  @override
  State<DialogoNuevoHogar> createState() => _DialogoNuevoHogarState();
}

class _DialogoNuevoHogarState extends State<DialogoNuevoHogar> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroCtrl;
  final TextEditingController _jefeFamiliaCtrl = TextEditingController();
  String? _sexoJefe;

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(text: widget.hogarSugerido.toString());
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _jefeFamiliaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.family_restroom, color: AppTheme.tertiary),
                  SizedBox(width: 12),
                  Text('Añadir Hogar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _numeroCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Número de Hogar',
                        hintText: 'Ej. 1, 2...',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Debe ser número';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jefeFamiliaCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Jefe(a) de Familia *',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sexo del Jefe(a) *'),
                      value: _sexoJefe,
                      items: ['Masculino', 'Femenino'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (v) => setState(() => _sexoJefe = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tertiary),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'numero': int.parse(_numeroCtrl.text),
                          'jefe_familia': _jefeFamiliaCtrl.text.trim(),
                          'sexo_jefe': _sexoJefe,
                        });
                      }
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
