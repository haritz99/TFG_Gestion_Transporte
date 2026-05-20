import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/plan_header.dart';
import 'widgets/calendario_cargas.dart';
import 'widgets/panel_asignacion_vehiculo.dart';
import 'widgets/lista_cargas_panel.dart';

class PlanificacionScreen extends StatelessWidget {
  const PlanificacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const PlanHeader(),
          Expanded(
            child: isDesktop
                ? const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: ListaCargasPanel(),
                        ),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: CalendarioCargas(),
                        ),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: PanelAsignacionVehiculo(),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: ListaCargasPanel(),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CalendarioCargas(),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: PanelAsignacionVehiculo(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
