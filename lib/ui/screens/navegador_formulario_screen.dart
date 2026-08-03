import 'package:flutter/material.dart';
import '../../core/models/jerarquia.dart';
import '../../core/models/capa_geometrica.dart';
import '../theme/app_theme.dart';

enum TipoJerarquia { nivel, local, hogar }

class NavegadorFormularioScreen extends StatefulWidget {
  final PuntoEstructura punto;
  final TipoJerarquia tipo;
  final int nivelIndex;
  final int? localIndex;
  final int? hogarIndex;
  final Function(PuntoEstructura) onGuardar;

  const NavegadorFormularioScreen({
    super.key,
    required this.punto,
    required this.tipo,
    required this.nivelIndex,
    this.localIndex,
    this.hogarIndex,
    required this.onGuardar,
  });

  @override
  State<NavegadorFormularioScreen> createState() => _NavegadorFormularioScreenState();
}

class _NavegadorFormularioScreenState extends State<NavegadorFormularioScreen> {
  late PuntoEstructura _punto;
  late int _nivelIndex;
  late int? _localIndex;
  late int? _hogarIndex;

  bool _isDirty = false;

  // Controladores Nivel
  late TextEditingController _nivelNumeroCtrl;
  int _nivelLocales = 1;

  // Controladores Local
  late TextEditingController _localNombreCtrl;
  late TextEditingController _localNumeroHogaresCtrl;
  String? _localUsoActual;
  String? _localOcupacion;

  // Controladores Hogar
  late TextEditingController _hogarJefeCtrl;
  late TextEditingController _hogarTotalHabitantesCtrl;
  String? _hogarSexoJefe;
  String? _hogarIdioma;
  final Map<String, TextEditingController> _edadesCtrls = {};

  @override
  void initState() {
    super.initState();
    _punto = widget.punto;
    _nivelIndex = widget.nivelIndex;
    _localIndex = widget.localIndex;
    _hogarIndex = widget.hogarIndex;
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    _nivelNumeroCtrl = TextEditingController();
    _localNombreCtrl = TextEditingController();
    _localNumeroHogaresCtrl = TextEditingController();
    _hogarJefeCtrl = TextEditingController();
    _hogarTotalHabitantesCtrl = TextEditingController();
    final list = ['0_5', '6_11', '12_17', '18_23', '24_34', '35_44', '45_59', '60_69', '70_79', '80_mas', 'no_edad'];
    for (var k in list) {
      _edadesCtrls[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nivelNumeroCtrl.dispose();
    _localNombreCtrl.dispose();
    _localNumeroHogaresCtrl.dispose();
    _hogarJefeCtrl.dispose();
    _hogarTotalHabitantesCtrl.dispose();
    for (var c in _edadesCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    _isDirty = false;
    final nivel = _punto.niveles[_nivelIndex];
    if (widget.tipo == TipoJerarquia.nivel) {
      _nivelNumeroCtrl.text = nivel.numeroNivel.toString();
      _nivelLocales = nivel.numeroLocales;
    } else if (widget.tipo == TipoJerarquia.local) {
      final local = nivel.locales[_localIndex!];
      _localNombreCtrl.text = local.nombre;
      _localUsoActual = local.usoActual;
      _localOcupacion = local.ocupacion;
      _localNumeroHogaresCtrl.text = local.numeroHogares?.toString() ?? '';
    } else if (widget.tipo == TipoJerarquia.hogar) {
      final hogar = nivel.locales[_localIndex!].hogares[_hogarIndex!];
      _hogarJefeCtrl.text = hogar.jefeFamilia;
      _hogarSexoJefe = hogar.sexoJefe;
      _hogarIdioma = hogar.idioma;
      _hogarTotalHabitantesCtrl.text = hogar.totalHabitantes?.toString() ?? '';
      _edadesCtrls['0_5']!.text = hogar.personas_0_5?.toString() ?? '';
      _edadesCtrls['6_11']!.text = hogar.personas_6_11?.toString() ?? '';
      _edadesCtrls['12_17']!.text = hogar.personas_12_17?.toString() ?? '';
      _edadesCtrls['18_23']!.text = hogar.personas_18_23?.toString() ?? '';
      _edadesCtrls['24_34']!.text = hogar.personas_24_34?.toString() ?? '';
      _edadesCtrls['35_44']!.text = hogar.personas_35_44?.toString() ?? '';
      _edadesCtrls['45_59']!.text = hogar.personas_45_59?.toString() ?? '';
      _edadesCtrls['60_69']!.text = hogar.personas_60_69?.toString() ?? '';
      _edadesCtrls['70_79']!.text = hogar.personas_70_79?.toString() ?? '';
      _edadesCtrls['80_mas']!.text = hogar.personas_80_mas?.toString() ?? '';
      _edadesCtrls['no_edad']!.text = hogar.personasNoEdad?.toString() ?? '';
    }
    setState(() {});
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final salir = await _mostrarDialogoSinGuardar();
    return salir ?? false;
  }

  Future<bool?> _mostrarDialogoSinGuardar() {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Existen cambios sin guardar.\n¿Desea guardar antes de continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c, true);
            },
            child: const Text('Descartar', style: TextStyle(color: AppTheme.error)),
          ),
          ElevatedButton(
            onPressed: () {
              _guardarDatos();
              Navigator.pop(c, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _guardarDatos() {
    Nivel nivel = _punto.niveles[_nivelIndex];
    if (widget.tipo == TipoJerarquia.nivel) {
      nivel = nivel.copyWith(
        numeroNivel: int.tryParse(_nivelNumeroCtrl.text) ?? nivel.numeroNivel,
        numeroLocales: _nivelLocales,
      );
    } else if (widget.tipo == TipoJerarquia.local) {
      Local local = nivel.locales[_localIndex!];
      local = local.copyWith(
        nombre: _localNombreCtrl.text,
        usoActual: _localUsoActual,
        ocupacion: _localOcupacion,
        numeroHogares: int.tryParse(_localNumeroHogaresCtrl.text),
      );
      final listLocales = List<Local>.from(nivel.locales);
      listLocales[_localIndex!] = local;
      nivel = nivel.copyWith(locales: listLocales);
    } else if (widget.tipo == TipoJerarquia.hogar) {
      Local local = nivel.locales[_localIndex!];
      Hogar hogar = local.hogares[_hogarIndex!];
      hogar = hogar.copyWith(
        jefeFamilia: _hogarJefeCtrl.text,
        sexoJefe: _hogarSexoJefe,
        idioma: _hogarIdioma,
        totalHabitantes: int.tryParse(_hogarTotalHabitantesCtrl.text),
        personas_0_5: int.tryParse(_edadesCtrls['0_5']!.text),
        personas_6_11: int.tryParse(_edadesCtrls['6_11']!.text),
        personas_12_17: int.tryParse(_edadesCtrls['12_17']!.text),
        personas_18_23: int.tryParse(_edadesCtrls['18_23']!.text),
        personas_24_34: int.tryParse(_edadesCtrls['24_34']!.text),
        personas_35_44: int.tryParse(_edadesCtrls['35_44']!.text),
        personas_45_59: int.tryParse(_edadesCtrls['45_59']!.text),
        personas_60_69: int.tryParse(_edadesCtrls['60_69']!.text),
        personas_70_79: int.tryParse(_edadesCtrls['70_79']!.text),
        personas_80_mas: int.tryParse(_edadesCtrls['80_mas']!.text),
        personasNoEdad: int.tryParse(_edadesCtrls['no_edad']!.text),
      );
      
      final listHogares = List<Hogar>.from(local.hogares);
      listHogares[_hogarIndex!] = hogar;
      
      local = local.copyWith(hogares: listHogares);
      final listLocales = List<Local>.from(nivel.locales);
      listLocales[_localIndex!] = local;
      
      nivel = nivel.copyWith(locales: listLocales);
    }

    final listNiveles = List<Nivel>.from(_punto.niveles);
    listNiveles[_nivelIndex] = nivel;
    _punto = _punto.copyWith(niveles: listNiveles);
    
    widget.onGuardar(_punto);
    _isDirty = false;
    setState(() {});
  }

  void _navegar(int delta) async {
    if (_isDirty) {
      final proceed = await _mostrarDialogoSinGuardar();
      if (proceed != true) return;
    }
    
    setState(() {
      if (widget.tipo == TipoJerarquia.nivel) {
        _nivelIndex += delta;
      } else if (widget.tipo == TipoJerarquia.local) {
        _localIndex = _localIndex! + delta;
      } else if (widget.tipo == TipoJerarquia.hogar) {
        _hogarIndex = _hogarIndex! + delta;
      }
      _loadData();
    });
  }

  int get _currentIndex {
    if (widget.tipo == TipoJerarquia.nivel) return _nivelIndex;
    if (widget.tipo == TipoJerarquia.local) return _localIndex!;
    return _hogarIndex!;
  }

  int get _totalItems {
    if (widget.tipo == TipoJerarquia.nivel) return _punto.niveles.length;
    final nivel = _punto.niveles[_nivelIndex];
    if (widget.tipo == TipoJerarquia.local) return nivel.locales.length;
    return nivel.locales[_localIndex!].hogares.length;
  }

  String get _tipoNombre {
    if (widget.tipo == TipoJerarquia.nivel) return 'Nivel';
    if (widget.tipo == TipoJerarquia.local) return 'Local';
    return 'Hogar';
  }

  Widget _buildBreadcrumbs() {
    String text = 'Estructura ${_punto.nombre ?? ""}';
    if (widget.tipo == TipoJerarquia.nivel) {
      text += ' > Nivel ${_nivelIndex + 1}/${_punto.niveles.length}';
    } else if (widget.tipo == TipoJerarquia.local) {
      final n = _punto.niveles[_nivelIndex];
      text += ' > Nivel ${n.numeroNivel} > Local ${_localIndex! + 1}/${n.locales.length}';
    } else {
      final n = _punto.niveles[_nivelIndex];
      final l = n.locales[_localIndex!];
      text += ' > Nivel ${n.numeroNivel} > Local ${l.nombre} > Hogar ${_hogarIndex! + 1}/${l.hogares.length}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceVariant.withOpacity(0.5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = _currentIndex > 0;
    final bool canGoForward = _currentIndex < _totalItems - 1;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$_tipoNombre ${_currentIndex + 1} de $_totalItems'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: canGoBack ? () => _navegar(-1) : null,
              tooltip: 'Anterior',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: canGoForward ? () => _navegar(1) : null,
              tooltip: 'Siguiente',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildBreadcrumbs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildForm(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar Cambios'),
              onPressed: _isDirty ? () {
                _guardarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cambios guardados')),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (widget.tipo == TipoJerarquia.nivel) return _buildNivelForm();
    if (widget.tipo == TipoJerarquia.local) return _buildLocalForm();
    return _buildHogarForm();
  }

  Widget _buildNivelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nivelNumeroCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Número de Nivel / Piso'),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _nivelLocales,
          decoration: const InputDecoration(labelText: 'Cantidad de Locales (Esperados)'),
          items: List.generate(30, (i) => i + 1).map((n) {
            return DropdownMenuItem(value: n, child: Text(n.toString()));
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _nivelLocales = v;
                _markDirty();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLocalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _localNombreCtrl,
          decoration: const InputDecoration(labelText: 'Identificador del Local'),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _localUsoActual,
          decoration: const InputDecoration(labelText: 'Uso actual'),
          items: const [
            DropdownMenuItem(value: 'Locales de habitación', child: Text('Locales de habitación')),
            DropdownMenuItem(value: 'Habitación y comercio', child: Text('Habitación y comercio')),
            DropdownMenuItem(value: 'Comercial', child: Text('Comercial')),
            DropdownMenuItem(value: 'Institución pública o privada', child: Text('Institución pública o privada')),
            DropdownMenuItem(value: 'Local en construcción', child: Text('Local en construcción')),
          ],
          onChanged: (v) {
            setState(() {
              _localUsoActual = v;
              if (_localUsoActual != 'Locales de habitación' && _localUsoActual != 'Habitación y comercio') {
                _localOcupacion = null;
              }
              _markDirty();
            });
          },
        ),
        if (_localUsoActual == 'Locales de habitación' || _localUsoActual == 'Habitación y comercio') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _localOcupacion,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Ocupación'),
            items: const [
              DropdownMenuItem(value: 'Vivienda con habitantes presentes', child: Text('Vivienda con habitantes presentes (con entrevista efectiva)')),
              DropdownMenuItem(value: 'Vivienda con habitantes ausentes', child: Text('Vivienda con habitantes ausentes (al momento de la visita)')),
              DropdownMenuItem(value: 'Vivienda de ocupación temporal', child: Text('Vivienda de ocupación temporal (vacacional, o alquiler)')),
              DropdownMenuItem(value: 'Vivienda desocupada', child: Text('Vivienda desocupada (en venta o abandono)')),
              DropdownMenuItem(value: 'Rechazo', child: Text('Rechazo (negativa de los informantes)')),
            ],
            onChanged: (v) {
              setState(() {
                _localOcupacion = v;
                _markDirty();
              });
            },
          ),
          if (_localOcupacion == 'Vivienda con habitantes presentes' || _localOcupacion == 'Vivienda con habitantes ausentes' ||
              _localOcupacion == 'Vivienda con habitantes presentes (con entrevista efectiva)' || _localOcupacion == 'Vivienda con habitantes ausentes (al momento de la visita)') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _localNumeroHogaresCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de Hogares *'),
              onChanged: (_) {
                setState(() {});
                _markDirty();
              },
            ),
          ],
        ],
        Builder(
          builder: (context) {
            final numHogares = int.tryParse(_localNumeroHogaresCtrl.text);
            final hogaresRegistrados = _punto.niveles[_nivelIndex].locales[_localIndex!].hogares.length;
            if (numHogares != null && numHogares != hogaresRegistrados && 
                (_localOcupacion?.contains('habitantes presentes') == true || _localOcupacion?.contains('habitantes ausentes') == true)) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Advertencia: El número de hogares esperado ($numHogares) no coincide con los hogares registrados ($hogaresRegistrados).',
                  style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                ),
              );
            }
            return const SizedBox();
          }
        ),
      ],
    );
  }

  int get _sumaEdades {
    int suma = 0;
    for (var c in _edadesCtrls.values) {
      suma += int.tryParse(c.text) ?? 0;
    }
    return suma;
  }

  Widget _buildHogarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _hogarJefeCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre del Jefe(a) de Familia'),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _hogarSexoJefe,
          decoration: const InputDecoration(labelText: 'Sexo del Jefe(a)'),
          items: ['Masculino', 'Femenino'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() {
              _hogarSexoJefe = v;
              _markDirty();
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _hogarIdioma,
          decoration: const InputDecoration(labelText: 'Idioma'),
          items: ['Español', 'Kekchi', 'Kakchiquel', 'Mam', 'Pocomam'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() {
              _hogarIdioma = v;
              _markDirty();
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hogarTotalHabitantesCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total de Habitantes'),
          onChanged: (_) {
            setState(() {});
            _markDirty();
          },
        ),
        const SizedBox(height: 24),
        const Text('Personas por Rango de Edad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...['0_5', '6_11', '12_17', '18_23', '24_34', '35_44', '45_59', '60_69', '70_79', '80_mas', 'no_edad'].map((k) {
          String label = k.replaceAll('_', ' a ');
          if (k == '80_mas') label = '80 o más';
          if (k == 'no_edad') label = 'No proporcionó edad';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextFormField(
              controller: _edadesCtrls[k],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Personas ($label)',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) {
                setState(() {});
                _markDirty();
              },
            ),
          );
        }).toList(),
        Builder(
          builder: (context) {
            final total = int.tryParse(_hogarTotalHabitantesCtrl.text) ?? 0;
            final suma = _sumaEdades;
            if (total != suma) {
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  border: Border.all(color: AppTheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Advertencia: El total de habitantes ($total) no coincide con la suma de las edades ($suma).',
                        style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          }
        ),
      ],
    );
  }
}
