import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/dashboard_calendar.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/panel_incidencias.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../features/auth/providers/auth_provider.dart';

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
    final authProvider = context.read<AuthProvider>();
    if (isMobile) {
      return Column(
        children: [
          DashboardCalendar(cargas: cargas),
          const SizedBox(height: 24),
          PanelIncidencias(),
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
        if (authProvider.user?.rol.contains('encargado') ?? false)
        Expanded(
          flex: 30,
          child: SizedBox(
            height: 700,
            child: PanelIncidencias(),
          ),
        ),
      ],
    );
  }

}
