import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/app_colors.dart';
import '../../dashboard/providers/invite_provider.dart';
import 'widgets/plan_header.dart';
import 'widgets/calendario_cargas.dart';
import 'widgets/panel_asignacion_vehiculo.dart';
import 'widgets/lista_cargas_panel.dart';
import '../../transportistas/providers/transportista_provider.dart';
import '../../vehiculos/providers/vehiculo_provider.dart';
import 'package:provider/provider.dart';

class PlanificacionScreen extends StatefulWidget {
  const PlanificacionScreen({super.key});

  @override
  State<PlanificacionScreen> createState() => _PlanificacionScreenState();
}

class _PlanificacionScreenState extends State<PlanificacionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transportistaProvider = context.read<TransportistaProvider>();
      final vehiculoProvider = context.read<VehiculoProvider>();
      final inviteProvider = context.read<InviteProvider>();

      Future.wait([
        transportistaProvider.fetchTransportistasDisponibles(),
        vehiculoProvider.loadInitialVehiculos(),
        inviteProvider.getGuests(),
      ]);
    });
  }

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
                ? Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: ListaCargasPanel(),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      const Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: CalendarioCargas(),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: const PanelAsignacionVehiculo(),
                        ),
                      ),
                    ],
                  )
                : Column(
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
                          padding: const EdgeInsets.all(16.0),
                          child: const PanelAsignacionVehiculo(),
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
