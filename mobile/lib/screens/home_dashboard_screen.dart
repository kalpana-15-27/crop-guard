import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/theme.dart';
import '../core/date_formatter.dart';
import '../localization/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/detection_provider.dart';
import '../widgets/crop_chip.dart';
import '../widgets/stat_card.dart';
import '../widgets/disclaimer_banner.dart';
import 'detection_result_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final void Function(int) onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  String _getGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.tr('greetingMorning');
    if (hour < 17) return strings.tr('greetingAfternoon');
    return strings.tr('greetingEvening');
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final strings = AppStrings();
    final auth = Provider.of<AuthProvider>(context);
    final detection = Provider.of<DetectionProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.leafGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              tr('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.deepForest),
            onPressed: () => onNavigateTab(3), // Navigate to Profile tab
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await auth.loadProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting & Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(strings),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        Text(
                          auth.displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => onNavigateTab(3),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.leafGreen.withValues(alpha: 0.15),
                        child: Text(
                          auth.displayName.isNotEmpty
                              ? auth.displayName[0].toUpperCase()
                              : 'F',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.leafGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Disclaimer Banner
                const DisclaimerBanner(),
                const SizedBox(height: 20),

                // Hero Scan Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.deepForest, AppTheme.leafGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.leafGreen.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lime.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'YOLO11s Deep Learning',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.lime,
                              ),
                            ),
                          ),
                          const Icon(Icons.shield_outlined, color: Colors.white70, size: 22),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr('quickScan'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('quickScanSubtitle'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await detection.pickImageFromCamera();
                                if (ok) onNavigateTab(1); // Go to Scan tab
                              },
                              icon: const Icon(Icons.camera_alt, size: 18, color: AppTheme.deepForest),
                              label: Text(
                                tr('camera'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.deepForest,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.lime,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await detection.pickImageFromGallery();
                                if (ok) onNavigateTab(1); // Go to Scan tab
                              },
                              icon: const Icon(Icons.photo_library, size: 18, color: Colors.white),
                              label: Text(
                                tr('gallery'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white60, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Supported Crops
                Text(
                  tr('supportedCrops'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConfig.supportedCrops.map((crop) {
                      final isSelected = detection.selectedCrop == crop;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CropChip(
                          label: crop,
                          isSelected: isSelected,
                          icon: Icons.grass,
                          onSelected: () => detection.setSelectedCrop(crop),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Live Actual Detection Statistics
                const Text(
                  'Detection Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: tr('statsTotalScans'),
                        value: detection.totalScans.toString(),
                        icon: Icons.qr_code_scanner,
                        iconColor: AppTheme.leafGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: tr('statsPestsDetected'),
                        value: detection.pestsDetectedCount.toString(),
                        icon: Icons.pest_control,
                        iconColor: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: tr('statsHealthyScans'),
                        value: detection.cleanScansCount.toString(),
                        icon: Icons.check_circle_outline,
                        iconColor: AppTheme.freshGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Agricultural Awareness Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.freshGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: AppTheme.leafGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('dailyTipTitle'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('dailyTipBody'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Scans Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('recentActivity'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (detection.historyList.isNotEmpty)
                      TextButton(
                        onPressed: () => onNavigateTab(2), // Navigate to History
                        child: Text(tr('viewAll')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (detection.historyList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight, width: 1),
                    ),
                    child: Text(
                      tr('noScansYet'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.mutedText),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detection.historyList.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = detection.historyList[index];
                      return ListTile(
                        tileColor: AppTheme.cardWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppTheme.borderLight, width: 1),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: item.isPestDetected
                              ? AppTheme.errorRed.withValues(alpha: 0.12)
                              : AppTheme.freshGreen.withValues(alpha: 0.12),
                          child: Icon(
                            item.isPestDetected ? Icons.bug_report : Icons.check,
                            color: item.isPestDetected ? AppTheme.errorRed : AppTheme.freshGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.isPestDetected
                              ? (item.primaryPest?.pestName ?? 'Pest Detected')
                              : tr('noPestDetected'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.cropType} • ${AppDateFormatter.formatDateTime(item.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
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
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
