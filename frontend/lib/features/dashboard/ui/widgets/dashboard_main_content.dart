import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/dashboard_calendar.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardMainContent extends StatelessWidget {
  final bool isMobile;
  final List<CargaModel> cargas;

  const DashboardMainContent({
    super.key,
    required this.isMobile,
    required this.cargas,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          DashboardCalendar(cargas: cargas),
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
          child: DashboardCalendar(cargas: cargas),
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
