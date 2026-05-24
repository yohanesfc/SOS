import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/activity_log.dart';
import '../providers/sos_provider.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'No activity logs yet.',
                style: TextStyle(color: AppColors.textDim),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                
                Color iconColor;
                IconData icon;
                
                switch (log.logLevel) {
                  case LogLevel.critical:
                    iconColor = AppColors.red;
                    icon = Icons.error;
                    break;
                  case LogLevel.warning:
                    iconColor = AppColors.orange;
                    icon = Icons.warning;
                    break;
                  case LogLevel.success:
                    iconColor = AppColors.green;
                    icon = Icons.check_circle;
                    break;
                  case LogLevel.info:
                  default:
                    iconColor = AppColors.textPrimary;
                    icon = Icons.info;
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm:ss').format(log.timestamp),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: logs.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: AppColors.surface2,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Clear Logs?', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('All activity logs will be cleared.', style: TextStyle(color: AppColors.textDim)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(activityLogProvider.notifier).clearAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear', style: TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.delete_sweep, color: AppColors.red),
            )
          : null,
    );
  }
}
