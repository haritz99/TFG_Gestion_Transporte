import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.0 : 1.25,
      children: [
        DashboardKpiCard(
          label: 'Cargas Activas',
          value: provider.cargasActivas.toString(),
        ),
        DashboardKpiCard(
          label: 'Cargas sin asignar',
          value: provider.cargasSinAsignar.toString(),
          bottomContent: Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              onTap: () {
                // TODO: Navegar a la pantalla de Cargas
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
          value: provider.incidenciasAbiertas.toString(),
          isAlert: provider.incidenciasAbiertas > 0,
          bottomContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.south_east,
                    color: provider.incidenciasAbiertas > 0
                        ? AppColors.warning
                        : Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.incidenciasAbiertas} críticas urgentes',
                    style: AppTextStyles.captionSemiBold.copyWith(
                      color: provider.incidenciasAbiertas > 0
                          ? AppColors.warning
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // TODO: Ir a pantalla de incidencias
                },
                child: Text(
                  'Ver incidencias >',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        DashboardKpiCard(
          label: 'Entregadas Hoy',
          value: '${provider.entregadasHoy}/${provider.totalEntregasHoy}',
        ),
      ],
    );
  }
}
