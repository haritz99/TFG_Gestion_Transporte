import 'package:flutter/material.dart';
import '../../../core/widgets/core_table/core_table_column.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/management_page_layout.dart';
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
      CoreTableColumn<FleetTableRowModel>(label: 'MATRÍCULA', flex: 13, cellBuilder: _buildMatriculaCell),
      CoreTableColumn<FleetTableRowModel>(label: 'MARCA', flex: 12, cellBuilder: _buildMarcaCell),
      CoreTableColumn<FleetTableRowModel>(label: 'MODELO', flex: 15, cellBuilder: _buildModeloCell),
      CoreTableColumn<FleetTableRowModel>(label: 'CAPACIDAD', flex: 10, cellBuilder: _buildCapacidadCell),
      CoreTableColumn<FleetTableRowModel>(label: 'LARGO', flex: 8, cellBuilder: _buildLargoCell),
      CoreTableColumn<FleetTableRowModel>(label: 'ANCHO', flex: 8, cellBuilder: _buildAnchoCell),
      CoreTableColumn<FleetTableRowModel>(label: 'ALTO', flex: 8, cellBuilder: _buildAltoCell),
      CoreTableColumn<FleetTableRowModel>(label: 'ESTADO', flex: 12, cellBuilder: _buildEstadoCell),
      CoreTableColumn<FleetTableRowModel>(label: 'INTERNO', flex: 13, cellBuilder: _buildInternoCell),
      CoreTableColumn<FleetTableRowModel>(label: 'MATRÍCULA REMOLQUE', flex: 17, cellBuilder: _buildRemolqueCell),
      CoreTableColumn<FleetTableRowModel>(label: 'CONDUCTOR', flex: 17, cellBuilder: _buildConductorCell),
    ],
    this.rows = const [],
    this.onStatusChanged,
    this.onAddVehiculo,
    this.onNuevaCarga,
    this.onDeleteVehiculo,
    this.onEditVehiculo,
    this.onMobileLoadMore,
    required this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final int? totalVehiculos;
  final int? asignados;
  final int? enMantenimiento;
  final int? disponibles;

  final String selectedStatus;
  final List<String> statusOptions;

  final List<CoreTableColumn<FleetTableRowModel>> columns;
  final List<FleetTableRowModel> rows;

  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onAddVehiculo;
  final VoidCallback? onNuevaCarga;
  final ValueChanged<String>? onDeleteVehiculo;
  final ValueChanged<String>? onEditVehiculo;
  final Future<void> Function()? onMobileLoadMore;
  final ValueChanged<int> onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  State<GestionFlotaPage> createState() =>
      _GestionFlotaPageState();
}

class _GestionFlotaPageState extends State<GestionFlotaPage> {
  @override
  Widget build(BuildContext context) {
    // Se añade la columna de ACCIONES para tener acceso a los callbacks y dejas this.columsn const
    final tableColumns = [
      ...widget.columns,
      CoreTableColumn<FleetTableRowModel>(
        label: 'ACCIONES',
        flex: 12,
        cellBuilder: (item) => Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
              onPressed: () => widget.onEditVehiculo?.call(item.matricula),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
              onPressed: () => widget.onDeleteVehiculo?.call(item.matricula),
            ),
          ],
        ),
      ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 900;
    return ManagementPageLayout(
      header: GestionFlotaHeader(
        onAddVehiculo: widget.onAddVehiculo,
        isMobile: isMobile,
      ),
      kpiGrid: FleetKpiGrid(
        totalVehiculos: widget.totalVehiculos,
        asignados: widget.asignados,
        enMantenimiento: widget.enMantenimiento,
        disponibles: widget.disponibles,
        isMobile: isMobile,
      ),
      table: FleetTable(
        rows: widget.rows,
        columns: tableColumns,
        selectedStatus: widget.selectedStatus,
        statusOptions: widget.statusOptions,
        onStatusChanged: widget.onStatusChanged,
        onDesktopPageChanged: widget.onDesktopPageChanged,
        hasMore: widget.hasMore,
        isLoadingMore: widget.isLoadingMore,
        onDeleteVehiculo: widget.onDeleteVehiculo,
        onEditVehiculo: widget.onEditVehiculo,
        isMobile: isMobile,
      ),
      onMobileLoadMore: widget.onMobileLoadMore,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
      isMobile: isMobile,
    );
  }
}

Widget _buildMatriculaCell(FleetTableRowModel item) => Text(item.matricula, style: AppTextStyles.tableValueStrong);
Widget _buildMarcaCell(FleetTableRowModel item) => Text(item.marca, style: AppTextStyles.tableValue);
Widget _buildModeloCell(FleetTableRowModel item) => Text(item.modelo, style: AppTextStyles.tableValue);
Widget _buildCapacidadCell(FleetTableRowModel item) => Text(item.capacidad, style: AppTextStyles.tableValue);
Widget _buildLargoCell(FleetTableRowModel item) => Text(item.largo, style: AppTextStyles.tableValue);
Widget _buildAnchoCell(FleetTableRowModel item) => Text(item.ancho, style: AppTextStyles.tableValue);
Widget _buildAltoCell(FleetTableRowModel item) => Text(item.alto, style: AppTextStyles.tableValue);
Widget _buildEstadoCell(FleetTableRowModel item) => Text(item.estado, style: AppTextStyles.tableValue);
Widget _buildInternoCell(FleetTableRowModel item) => Text(item.interno, style: AppTextStyles.tableValue);
Widget _buildRemolqueCell(FleetTableRowModel item) => Text(item.matriculaRemolque, style: AppTextStyles.tableValue);
Widget _buildConductorCell(FleetTableRowModel item) => Text(item.conductor, style: AppTextStyles.tableValue);
