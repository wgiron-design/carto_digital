import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/services/nivel_service.dart';
import 'progress_strip.dart';

class ListaJerarquicaCard extends StatelessWidget {
  final NivelResumen nivel;
  final VoidCallback onEditar;
  final VoidCallback? onContinuar;

  const ListaJerarquicaCard({
    super.key,
    required this.nivel,
    required this.onEditar,
    this.onContinuar,
  });

  SegmentStatus get _estado {
    if (nivel.localesRegistrados == 0) {
      return SegmentStatus.sinIniciar;
    } else if (nivel.localesRegistrados >= nivel.numeroLocales) {
      return SegmentStatus.completo;
    } else {
      return SegmentStatus.enCurso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _estado;

    Color borderColor = Colors.transparent;
    Widget leadingIcon;
    Widget? chipWidget;

    switch (estado) {
      case SegmentStatus.completo:
        borderColor = AppTheme.success.withOpacity(0.4);
        leadingIcon = Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        );
        break;

      case SegmentStatus.enCurso:
        borderColor = AppTheme.primary;
        leadingIcon = Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2),
          ),
          child: const Icon(Icons.edit, size: 16, color: AppTheme.primary),
        );
        chipWidget = ActionChip(
          avatar: const Icon(Icons.play_arrow, size: 14, color: Color(0xFF003731)),
          label: const Text('Continuar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primary,
          labelStyle: const TextStyle(color: Color(0xFF003731)),
          padding: EdgeInsets.zero,
          onPressed: onContinuar ?? onEditar,
        );
        break;

      case SegmentStatus.sinIniciar:
        borderColor = AppTheme.surfaceVariant;
        leadingIcon = Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 2, style: BorderStyle.solid),
          ),
        );
        break;
    }

    return Card(
      color: AppTheme.surface,
      elevation: estado == SegmentStatus.enCurso ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: estado == SegmentStatus.enCurso ? 2 : 1),
      ),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leadingIcon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nivel ${nivel.numero}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        if (nivel.descripcion != null && nivel.descripcion!.isNotEmpty)
                          Text(
                            nivel.descripcion!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (chipWidget != null) chipWidget,
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
                    onPressed: onEditar,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${nivel.localesRegistrados} de ${nivel.numeroLocales} locales',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    '${nivel.hogaresRegistrados} hogares · ${nivel.personasRegistradas} pers.',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
