import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'models/fleet_column_def.dart';
import 'models/fleet_table_row_model.dart';
import 'widgets/fleet_kpi_grid.dart';
import 'widgets/fleet_table.dart';
import 'widgets/gestion_flota_header.dart';

class GestionFlotaPage extends StatefulWidget {
  const GestionFlotaPage({
    super.key,
    this.totalVehiculos,
    this.asignados,
    this.enMantenimiento,
    this.disponibles,
    this.selectedStatus = 'Todos',
    this.statusOptions = const [
      'Todos',
      'Asignado',
      'Disponible',
      'Mantenimiento',
    ],
    this.columns = const [
      FleetColumnDef('MATRICULA', 13),
      FleetColumnDef('MARCA', 12),
      FleetColumnDef('MODELO', 15),
      FleetColumnDef('CAPACIDAD', 10),
      FleetColumnDef('LARGO', 8),
      FleetColumnDef('ANCHO', 8),
      FleetColumnDef('ALTO', 8),
      FleetColumnDef('ESTADO', 12),
      FleetColumnDef('INTERNO', 13),
      FleetColumnDef('MATRICULA REMOLQUE', 17),
      FleetColumnDef('CONDUCTOR', 17),
      FleetColumnDef('ACCIONES', 12),
    ],
    this.rows = const [],
    this.onStatusChanged,
    this.onAddVehiculo,
    this.onNuevaCarga,
    this.onDeleteVehiculo,
    this.onEditVehiculo,
    this.onMobileLoadMore,
    this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final int? totalVehiculos;
  final int? asignados;
  final int? enMantenimiento;
  final int? disponibles;

  final String selectedStatus;
  final List<String> statusOptions;

  final List<FleetColumnDef> columns;
  final List<FleetTableRowModel> rows;

  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onAddVehiculo;
  final VoidCallback? onNuevaCarga;
  final ValueChanged<String>? onDeleteVehiculo;
  final ValueChanged<String>? onEditVehiculo;
  final Future<void> Function()? onMobileLoadMore;
  final ValueChanged<int>? onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;

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
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!isMobile || !widget.hasMore || widget.isLoadingMore) {
                return false;
              }
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 120) {
                widget.onMobileLoadMore?.call();
              }
              return false;
            },
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
                  SizedBox(height: isMobile ? 10 : 16),
                  FleetKpiGrid(
                    totalVehiculos: widget.totalVehiculos,
                    asignados: widget.asignados,
                    enMantenimiento: widget.enMantenimiento,
                    disponibles: widget.disponibles,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 10 : 16),
                  FleetTable(
                    rows: widget.rows,
                    columns: widget.columns,
                    selectedStatus: widget.selectedStatus,
                    statusOptions: widget.statusOptions,
                    onStatusChanged: widget.onStatusChanged,
                    onDeleteVehiculo: widget.onDeleteVehiculo,
                    onEditVehiculo: widget.onEditVehiculo,
                    isMobile: isMobile,
                    hasMore: widget.hasMore,
                    isLoadingMore: widget.isLoadingMore,
                    onDesktopPageChanged: widget.onDesktopPageChanged,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
