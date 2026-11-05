import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/theme.dart';
import '../core/date_formatter.dart';
import '../localization/app_strings.dart';
import '../providers/detection_provider.dart';
import '../widgets/empty_state.dart';
import 'detection_result_screen.dart';

class DetectionHistoryScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;

  const DetectionHistoryScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DetectionHistoryScreen> createState() => _DetectionHistoryScreenState();
}

class _DetectionHistoryScreenState extends State<DetectionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DetectionProvider>(context, listen: false).syncRemoteHistory();
      }
    });
  }

  Widget _buildThumbnail(dynamic item, bool hasPest) {
    if (!kIsWeb && item.imagePath != null && File(item.imagePath!).existsSync()) {
      return Image.file(
        File(item.imagePath!),
        fit: BoxFit.cover,
      );
    }

    final String? networkUrl = item.annotatedImagePath ?? item.imagePath;
    if (networkUrl != null && networkUrl.isNotEmpty) {
      final fullUrl = networkUrl.startsWith('http')
          ? networkUrl
          : '${AppConfig.backendBaseUrl}$networkUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          hasPest ? Icons.bug_report : Icons.check_circle,
          color: hasPest ? AppTheme.errorRed : AppTheme.freshGreen,
        ),
      );
    }

    return Icon(
      hasPest ? Icons.bug_report : Icons.check_circle,
      color: hasPest ? AppTheme.errorRed : AppTheme.freshGreen,
    );
  }

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
          IconButton(
            icon: detection.isSyncingHistory
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.leafGreen),
                  )
                : const Icon(Icons.sync, color: AppTheme.leafGreen),
            tooltip: 'Sync Cloud Scans',
            onPressed: detection.isSyncingHistory
                ? null
                : () async {
                    await detection.syncRemoteHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account scans synced from cloud'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
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
        child: RefreshIndicator(
          onRefresh: () => detection.syncRemoteHistory(),
          color: AppTheme.leafGreen,
          child: detection.isSyncingHistory && history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.leafGreen),
                      SizedBox(height: 16),
                      Text(
                        'Syncing account scans from cloud...',
                        style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : history.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        EmptyState(
                          icon: Icons.history_edu_outlined,
                          title: tr('noScansYet'),
                          message: 'Your scanned pest records and diagnosis recommendations will appear here.\nPull down to sync across devices.',
                          buttonText: tr('quickScan'),
                          onButtonPressed: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1);
                            }
                          },
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                  child: _buildThumbnail(item, hasPest),
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
                                    '${item.cropType} • ${AppDateFormatter.formatDateTime(item.createdAt)}',
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
      ),
    );
  }
}
