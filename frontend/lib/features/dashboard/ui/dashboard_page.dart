import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../../cargas/providers/carga_provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_kpi_grid.dart';
import 'widgets/dashboard_main_content.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final cargaProvider = context.watch<CargaProvider>();

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;

      if (provider.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (provider.errorMessage != null) {
        return Center(
          child: Text(
            provider.errorMessage!,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.warning),
          ),
        );
      }

      return Container(
        color: AppColors.pageBackground,
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardHeader(),
                const SizedBox(height: 18),
                DashboardKpiGrid(isMobile: isMobile, provider: provider),
                const SizedBox(height: 18),
                DashboardMainContent(cargas: cargaProvider.cargas, isMobile: isMobile),
              ],
            ),
          ),
        ),
      );
    });
  }
}
