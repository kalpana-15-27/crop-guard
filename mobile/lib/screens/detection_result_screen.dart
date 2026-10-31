import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../models/pest_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/disclaimer_banner.dart';

class DetectionResultScreen extends StatefulWidget {
  final DetectionResult result;

  const DetectionResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  bool _showAnnotated = true;

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final isTe = AppStrings().isTelugu;
    final result = widget.result;
    final pest = result.primaryPest;
    final hasPest = result.isPestDetected;

    // Bilingual description & guidance
    final description = isTe && pest?.descriptionTe != null && pest!.descriptionTe!.isNotEmpty
        ? pest.descriptionTe!
        : (pest?.description ?? 'No detailed description available.');

    final symptoms = isTe && pest?.symptomsTe != null && pest!.symptomsTe!.isNotEmpty
        ? pest.symptomsTe!
        : (pest?.symptoms ?? 'Monitor crops closely for localized foliage stress.');

    final guidance = isTe && pest?.preventiveGuidanceTe != null && pest!.preventiveGuidanceTe!.isNotEmpty
        ? pest.preventiveGuidanceTe!
        : (pest?.preventiveGuidance ?? 'Maintain weed-free field borders and consult local Krishi Vigyan Kendra (KVK).');

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('resultTitle')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disclaimer Banner
              const DisclaimerBanner(),
              const SizedBox(height: 16),

              // Image Viewer (Original vs Annotated Toggle)
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (result.imagePath != null && File(result.imagePath!).existsSync())
                        Image.file(
                          File(result.imagePath!),
                          fit: BoxFit.cover,
                        )
                      else
                        const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                        ),

                      // Overlay toggle pill
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InkWell(
                          onTap: () => setState(() => _showAnnotated = !_showAnnotated),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showAnnotated ? Icons.visibility : Icons.visibility_off,
                                  color: hasPest ? AppTheme.lime : AppTheme.freshGreen,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _showAnnotated ? 'Annotated (${result.cropType})' : 'Original (${result.cropType})',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasPest ? AppTheme.errorRed.withValues(alpha: 0.3) : AppTheme.freshGreen.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasPest
                                ? AppTheme.errorRed.withValues(alpha: 0.12)
                                : AppTheme.freshGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasPest ? Icons.pest_control : Icons.verified,
                            color: hasPest ? AppTheme.errorRed : AppTheme.freshGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasPest
                                    ? (pest?.pestName ?? 'Detected Pest')
                                    : tr('noPestDetected'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: hasPest ? AppTheme.errorRed : AppTheme.deepForest,
                                ),
                              ),
                              if (pest?.scientificName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  pest!.scientificName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: 14),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          tr('confidence'),
                          hasPest ? '${(result.highestConfidence * 100).toStringAsFixed(1)}%' : 'N/A',
                          Icons.analytics_outlined,
                        ),
                        _buildMetricCol(
                          tr('pestCount'),
                          '${result.totalDetections}',
                          Icons.numbers,
                        ),
                        _buildMetricCol(
                          'Latency',
                          '${result.processingTimeSec.toStringAsFixed(2)}s',
                          Icons.timer_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // If No Pest Detected
              if (!hasPest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.freshGreen, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('noPestMessage'),
                          style: const TextStyle(fontSize: 13.5, color: AppTheme.darkText, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Pest Details & Symptoms Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description_outlined, color: AppTheme.leafGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Description',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 13.5, color: AppTheme.darkText, height: 1.45),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr('damageSymptoms'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        symptoms,
                        style: const TextStyle(fontSize: 13.5, color: AppTheme.darkText, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Preventive Guidance Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.leafGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.leafGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('preventiveGuidance'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.deepForest),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        guidance,
                        style: const TextStyle(fontSize: 13.5, color: AppTheme.darkText, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Bottom Button
              CustomButton(
                text: tr('scanAnother'),
                icon: Icons.camera_alt_outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.leafGreen),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.darkText),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
