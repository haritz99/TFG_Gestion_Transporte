import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'models/fleet_table_row_model.dart';
import 'widgets/fleet_kpi_grid.dart';
import 'widgets/fleet_table.dart';
import 'widgets/gestion_flota_header.dart';

class GestionFlotaPage extends StatefulWidget {
  const GestionFlotaPage({
    super.key,
    this.totalVehiculos,
    this.activos,
    this.enMantenimiento,
    this.disponibles,
    this.selectedStatus = 'Todos',
    this.statusOptions = const [
      'Todos',
      'Activo',
      'Mantenimiento',
      'Inactivo',
      'Disponible',
    ],
    this.columns = const [
      'MATRICULA',
      'MARCA',
      'MODELO',
      'CAPACIDAD',
      'LARGO',
      'ANCHO',
      'ALTO',
      'DISPONIBLE',
      'INTERNO',
      'MATRICULA REMOLQUE',
      'TRANSPORTISTA ASIGNADO',
      'ACCIONES',
    ],
    this.rows = const [],
    this.onStatusChanged,
    this.onAddVehiculo,
    this.onNuevaCarga,
  });

  final int? totalVehiculos;
  final int? activos;
  final int? enMantenimiento;
  final int? disponibles;

  final String selectedStatus;
  final List<String> statusOptions;

  final List<String> columns;
  final List<FleetTableRowModel> rows;

  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onAddVehiculo;
  final VoidCallback? onNuevaCarga;

  @override
  State<GestionFlotaPage> createState() =>
      _GestionFlotaPageState();
}

class _GestionFlotaPageState
    extends State<GestionFlotaPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Container(
          color: AppColors.pageBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestionFlotaHeader(
                  onAddVehiculo: widget.onAddVehiculo,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                FleetKpiGrid(
                  totalVehiculos: widget.totalVehiculos,
                  activos: widget.activos,
                  enMantenimiento: widget.enMantenimiento,
                  disponibles: widget.disponibles,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                FleetTable(
                  rows: widget.rows,
                  columns: widget.columns,
                  selectedStatus: widget.selectedStatus,
                  statusOptions: widget.statusOptions,
                  onStatusChanged: widget.onStatusChanged,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
