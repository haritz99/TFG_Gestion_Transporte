import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_mobile_card.dart';
import '../../../../core/widgets/core_table/core_table_column.dart';
import '../models/fleet_table_row_model.dart';

class FleetTable extends StatelessWidget {
  const FleetTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.selectedStatus,
    required this.statusOptions,
    required this.isMobile,
    this.onStatusChanged,
    required this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onDeleteVehiculo,
    this.onEditVehiculo,
  });

  final List<FleetTableRowModel> rows;
  final List<CoreTableColumn<FleetTableRowModel>> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final ValueChanged<String>? onStatusChanged;
  final ValueChanged<int> onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;
  final ValueChanged<String>? onDeleteVehiculo;
  final ValueChanged<String>? onEditVehiculo;

  @override
  Widget build(BuildContext context) {
    return CoreTable<FleetTableRowModel>(
      rows: rows,
      columns: columns,
      selectedStatus: selectedStatus,
      statusOptions: statusOptions,
      isMobile: isMobile,
      onStatusChanged: onStatusChanged,
      onDesktopPageChanged: onDesktopPageChanged,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      mobileCardBuilder: (vehiculo) => CoreMobileCard(
        title: vehiculo.matricula,
        onEdit: () => onEditVehiculo?.call(vehiculo.matricula),
        onDelete: () => onDeleteVehiculo?.call(vehiculo.matricula),
        details: [
          MapEntry('Marca', vehiculo.marca),
          MapEntry('Modelo', vehiculo.modelo),
          MapEntry('Capacidad', vehiculo.capacidad),
          MapEntry('Dimensiones', '${vehiculo.largo} x ${vehiculo.ancho} x ${vehiculo.alto}'),
          MapEntry('Estado', vehiculo.estado),
          MapEntry('Interno', vehiculo.interno),
          MapEntry('Remolque', vehiculo.matriculaRemolque),
          MapEntry('Conductor', vehiculo.conductor),
        ],
      ),
    );
  }
}
