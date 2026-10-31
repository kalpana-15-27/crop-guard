import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../providers/detection_provider.dart';
import '../widgets/crop_chip.dart';
import '../widgets/custom_button.dart';
import '../widgets/disclaimer_banner.dart';
import 'detection_result_screen.dart';

class ImageCaptureScreen extends StatelessWidget {
  const ImageCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final detection = Provider.of<DetectionProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('scanTitle')),
        actions: [
          if (detection.selectedImage != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              tooltip: tr('remove'),
              onPressed: () => detection.clearSelectedImage(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disclaimer Banner
              const DisclaimerBanner(),
              const SizedBox(height: 18),

              // Crop Selector
              Text(
                tr('selectCrop'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConfig.supportedCrops.map((crop) {
                    final isSelected = detection.selectedCrop == crop;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CropChip(
                        label: crop,
                        isSelected: isSelected,
                        onSelected: () => detection.setSelectedCrop(crop),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Image Capture Viewport / Preview
              Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: detection.selectedImage != null
                        ? AppTheme.leafGreen
                        : AppTheme.borderLight,
                    width: detection.selectedImage != null ? 2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: detection.selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              detection.selectedImage!,
                              fit: BoxFit.cover,
                            ),
                            // Semi-transparent controls on preview
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  detection.selectedCrop,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 44,
                                color: AppTheme.leafGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                tr('capturePrompt'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Camera & Gallery
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: detection.isAnalyzing
                          ? null
                          : () => detection.pickImageFromCamera(),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        detection.selectedImage != null ? tr('retake') : tr('camera'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: detection.isAnalyzing
                          ? null
                          : () => detection.pickImageFromGallery(),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        tr('gallery'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Analyze / Submit Button
              CustomButton(
                text: tr('analyzeButton'),
                isLoading: detection.isAnalyzing,
                icon: Icons.search,
                onPressed: detection.selectedImage == null || detection.isAnalyzing
                    ? null
                    : () async {
                        final ok = await detection.analyzeSelectedImage();
                        if (ok && context.mounted && detection.currentResult != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetectionResultScreen(
                                result: detection.currentResult!,
                              ),
                            ),
                          );
                        } else if (detection.errorMessage != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(detection.errorMessage!),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Loading Feedback
              if (detection.isAnalyzing) ...[
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.leafGreen),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('analyzing'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
