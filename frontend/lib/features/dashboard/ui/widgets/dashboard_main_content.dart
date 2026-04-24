import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardMainContent extends StatelessWidget {
  final bool isMobile;

  const DashboardMainContent({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _buildPlaceholderCard('Calendario de Cargas', 400),
          const SizedBox(height: 24),
          _buildPlaceholderCard('Panel de Incidencias Críticas', 300),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 70,
          child: _buildPlaceholderCard('Calendario de Cargas', 600),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 30,
          child: _buildPlaceholderCard('Panel de Incidencias Críticas', 600),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard(String title, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          title,
          style: AppTextStyles.headingMd.copyWith(
            color: AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}
