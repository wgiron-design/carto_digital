import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SegmentStatus { completo, enCurso, sinIniciar }

class ProgressStrip extends StatelessWidget {
  final int total;
  final int actualIndex;
  final List<SegmentStatus>? estados;

  const ProgressStrip({
    super.key,
    required this.total,
    required this.actualIndex,
    this.estados,
  });

  @override
  Widget build(BuildContext context) {
    final int safeTotal = total < 1 ? 1 : total;
    final int displayActual = (actualIndex + 1).clamp(1, safeTotal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de Niveles',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface.withOpacity(0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nivel $displayActual de $safeTotal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(safeTotal, (index) {
              Color color;
              if (estados != null && index < estados!.length) {
                switch (estados![index]) {
                  case SegmentStatus.completo:
                    color = AppTheme.success;
                    break;
                  case SegmentStatus.enCurso:
                    color = AppTheme.primary;
                    break;
                  case SegmentStatus.sinIniciar:
                    color = AppTheme.surfaceVariant;
                    break;
                }
              } else {
                if (index < actualIndex) {
                  color = AppTheme.success;
                } else if (index == actualIndex) {
                  color = AppTheme.primary;
                } else {
                  color = AppTheme.surfaceVariant;
                }
              }

              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == safeTotal - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
