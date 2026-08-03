import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';

/// Panel de logs para mostrar el historial de operaciones
class LogPanel extends StatelessWidget {
  final List<String> logs;
  final VoidCallback onClear;

  const LogPanel({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header del panel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Log de Operaciones',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                '${logs.length} entradas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              if (logs.isNotEmpty)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline, size: 14, color: AppTheme.error),
                        const SizedBox(width: 4),
                        Text(
                          'Limpiar',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Área de logs
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1520),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E3050),
                width: 1,
              ),
            ),
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.playlist_play,
                          size: 40,
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin operaciones registradas.\nEjecuta una acción para ver el log.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isError = log.contains('❌');
                      final isSuccess = log.contains('✅');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            color: isError
                                ? AppTheme.error
                                : isSuccess
                                    ? AppTheme.success
                                    : const Color(0xFF90A4AE),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
