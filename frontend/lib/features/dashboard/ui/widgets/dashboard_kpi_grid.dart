import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../incidencias/incidencias_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_kpi_card.dart';

class DashboardKpiGrid extends StatelessWidget {
  final bool isMobile;
  final DashboardProvider provider;

  const DashboardKpiGrid({
    super.key,
    required this.isMobile,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final incidenciasCount = context.watch<IncidenciaProvider>().incidencias.length;
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.0 : 1.75,
      children: [
        DashboardKpiCard(
          label: 'Cargas asignadas esta semana',
          value: provider.cargasAsignadas.toString(),
        ),
        DashboardKpiCard(
          label: 'Cargas pendientes esta semana',
          value: provider.cargasSinAsignar.toString(),
          bottomContent: Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              onTap: () {
                context.push('/planificacion');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Asignar ahora',
                  style: AppTextStyles.buttonSmall,
                ),
              ),
            ),
          ),
        ),
        DashboardKpiCard(
          label: 'Incidencias Abiertas',
          value: incidenciasCount.toString(),
        ),
        DashboardKpiCard(
          label: 'Entregadas Hoy',
          value: '${provider.entregadasHoy}/${provider.totalEntregasHoy}',
        ),
      ],
    );
  }
}
