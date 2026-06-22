import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../dashboard/ui/widgets/dashboard_main_content.dart';
import 'conductorProvider.dart';
import 'conductores_kpi_grid.dart';

class ConductorPage extends StatelessWidget {

  const ConductorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConductorProvider>();

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;

      if (provider.isLoading) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (provider.errorMessage != null) {
        return Center(
          child:
          Text(provider.errorMessage!,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.warning)),
        );
      }

      return Container(
          color: AppColors.pageBackground,
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 24,
                      vertical: isMobile ? 12 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConductoresKpiGrid(isMobile: isMobile, provider: provider),
                        const SizedBox(height: 18),
                        DashboardMainContent(
                          cargas: provider.cargas,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
      );
    });
  }
}