import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warningAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('experimentalDisclaimer'),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.darkText,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
