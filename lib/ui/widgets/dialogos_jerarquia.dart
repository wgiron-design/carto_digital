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





