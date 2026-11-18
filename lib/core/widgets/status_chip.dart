import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? colorForStatus(label);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: effectiveColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static Color colorForStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('tolak') || normalized.contains('tidak aktif')) {
      return AppColors.danger;
    }
    if (normalized.contains('setuju') ||
        normalized.contains('selesai') ||
        normalized.contains('aktif') ||
        normalized.contains('dibayar') ||
        normalized.contains('tepat')) {
      return AppColors.success;
    }
    if (normalized.contains('jalan') || normalized.contains('proses')) {
      return AppColors.primary;
    }
    return AppColors.warning;
  }
}
