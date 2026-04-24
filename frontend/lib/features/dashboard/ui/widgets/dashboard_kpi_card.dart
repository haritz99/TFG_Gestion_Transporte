import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;
  final Widget? bottomContent;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.isAlert = false,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isAlert ? AppColors.warning : AppColors.titleText;
    final labelColor = AppColors.mutedText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (bottomContent != null) ...[
            const Spacer(),
            bottomContent!,
          ]
        ],
      ),
    );
  }
}
