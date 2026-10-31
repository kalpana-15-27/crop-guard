import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../providers/detection_provider.dart';
import '../widgets/empty_state.dart';
import 'detection_result_screen.dart';

class DetectionHistoryScreen extends StatelessWidget {
  final void Function(int)? onNavigateTab;

  const DetectionHistoryScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final detection = Provider.of<DetectionProvider>(context);
    final history = detection.historyList;

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('historyTitle')),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.errorRed),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('deleteConfirmTitle')),
                    content: Text(tr('deleteConfirmBody')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr('cancel')),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                        onPressed: () {
                          detection.clearHistory();
                          Navigator.pop(ctx);
                        },
                        child: Text(tr('delete'), style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: history.isEmpty
            ? EmptyState(
                icon: Icons.history_edu_outlined,
                title: tr('noScansYet'),
                message: 'Your scanned pest records and diagnosis recommendations will appear here.',
                buttonText: tr('quickScan'),
                onButtonPressed: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(1); // Navigate to Scan Tab
                  }
                },
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final hasPest = item.isPestDetected;

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      detection.removeHistoryItem(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scan record deleted'),
                          backgroundColor: AppTheme.errorRed,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.surfaceMuted,
                            child: item.imagePath != null && File(item.imagePath!).existsSync()
                                ? Image.file(
                                    File(item.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    hasPest ? Icons.bug_report : Icons.check_circle,
                                    color: hasPest ? AppTheme.errorRed : AppTheme.freshGreen,
                                  ),
                          ),
                        ),
                        title: Text(
                          hasPest
                              ? (item.primaryPest?.pestName ?? 'Pest Detected')
                              : tr('noPestDetected'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${item.cropType} • ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
                            ),
                            if (hasPest) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${(item.highestConfidence * 100).toStringAsFixed(0)}% match',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.errorRed),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.totalDetections} found',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedText),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetectionResultScreen(result: item),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
