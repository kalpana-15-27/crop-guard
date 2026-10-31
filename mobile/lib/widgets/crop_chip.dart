import 'package:flutter/material.dart';
import '../core/theme.dart';

class CropChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  const CropChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.borderLight, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.leafGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.leafGreen,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
