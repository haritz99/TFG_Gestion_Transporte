import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/dashboard_calendar.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/panel_incidencias.dart';
import 'package:gestion_transporte/features/cargas/ui/panel_editar_carga.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class DashboardMainContent extends StatelessWidget {
  final bool isMobile;
  final List<CargaModel> cargas;
  final CargaModel? cargaSeleccionada;
  final Function(CargaModel)? onCargaTap;
  final VoidCallback? onCerrarEdicion;

  const DashboardMainContent({
    super.key,
    required this.isMobile,
    required this.cargas,
    this.cargaSeleccionada,
    this.onCargaTap,
    this.onCerrarEdicion,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final esEncargado = authProvider.user?.rol.contains('encargado') ?? false;
    if (isMobile) {
      return Column(
        children: [
          DashboardCalendar(cargas: cargas, onCargaTap: onCargaTap),
          const SizedBox(height: 24),
          if (cargaSeleccionada != null)
            SizedBox(
              height: 600,
              child: PanelEditarCarga(carga: cargaSeleccionada!, onCerrar: () => onCerrarEdicion?.call()),
            )
          else
            const PanelIncidencias(internalScroll: false),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 70,
          child: DashboardCalendar(cargas: cargas, onCargaTap: onCargaTap),
        ),
        const SizedBox(width: 24),
        if (esEncargado)
          Expanded(
            flex: 30,
            child: cargaSeleccionada != null
                ? SizedBox(height: 700,
                    child: PanelEditarCarga(carga: cargaSeleccionada!, onCerrar: () => onCerrarEdicion?.call()),
                  ) : const SizedBox(height: 700,
                    child: PanelIncidencias(internalScroll: true),
                  ),
          ),
      ],
    );
  }

}
