import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/fleet_column_def.dart';
import '../models/fleet_table_row_model.dart';

class FleetTable extends StatefulWidget {
  const FleetTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.selectedStatus,
    required this.statusOptions,
    required this.isMobile,
    this.onStatusChanged,
    this.onDeleteVehiculo,
    this.onEditVehiculo,
    this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.rowsPerPage = 6,
  });

  final List<FleetTableRowModel> rows;
  final List<FleetColumnDef> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final ValueChanged<String>? onStatusChanged;
  final ValueChanged<String>? onDeleteVehiculo;
  final ValueChanged<String>? onEditVehiculo;
  final ValueChanged<int>? onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;
  final int rowsPerPage;

  @override
  State<FleetTable> createState() => _FleetTableState();
}

class _FleetTableState extends State<FleetTable> {
  // Esta clase controla el estado de la tabla y sus filtros
  late String _selectedStatus;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  @override
  void didUpdateWidget(covariant FleetTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStatus != oldWidget.selectedStatus) {
      _selectedStatus = widget.selectedStatus;
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildStatusFilter(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF5)),
          if (widget.rows.isEmpty)
            _buildEmptyState()
          else if (widget.isMobile)
            _buildMobileCards()
          else
            _buildDesktopTable(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.rows.length} vehículos',
                style: AppTextStyles.bodyMd,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedStatus,
        tooltip: 'Filtrar por estado',
        offset: const Offset(0, 42),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          setState(() {
            _selectedStatus = value;
          });
          widget.onStatusChanged?.call(value);
        },
        itemBuilder: (context) {
          return widget.statusOptions
              .map(
                (status) => PopupMenuItem<String>(
                  value: status,
                  child: Text(
                    'Estado: $status',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Color(0xFF4A5E79),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Estado: $_selectedStatus',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Color(0xFF4A5E79),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    final source = _FleetDesktopSource(
      rows: widget.rows,
      columns: widget.columns,
      onDelete: widget.onDeleteVehiculo,
      onEdit: widget.onEditVehiculo,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
      rowsPerPage: widget.rowsPerPage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 1350 ? constraints.maxWidth : 1350.0;

        return SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors.transparent,
                dividerColor: const Color(0xFFE8EDF5),
              ),
              child: PaginatedDataTable(
                columns: widget.columns
                    .map((col) => DataColumn(label: Text(col.label, style: AppTextStyles.tableHeader)))
                    .toList(),
                source: source,
                showCheckboxColumn: false,
                rowsPerPage: widget.rowsPerPage,
                availableRowsPerPage: const [6],
                onRowsPerPageChanged: (_) {},
                onPageChanged: widget.onDesktopPageChanged,
                showFirstLastButtons: true,
                headingRowHeight: 44,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                horizontalMargin: 16,
                columnSpacing: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCards() {
    final itemCount = widget.rows.length + (widget.isLoadingMore ? 1 : 0);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF0F3F8)),
      itemBuilder: (_, index) {
        if (index >= widget.rows.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _FleetVehicleCard(
          data: widget.rows[index],
          onDelete: widget.onDeleteVehiculo,
          onEdit: widget.onEditVehiculo,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.mutedText),
          SizedBox(width: 10),
          Text('Sin datos para mostrar', style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

class _FleetDesktopSource extends DataTableSource {
  _FleetDesktopSource({
    required this.rows,
    required this.columns,
    required this.onDelete,
    required this.onEdit,
    required this.hasMore,
    required this.isLoadingMore,
    required this.rowsPerPage,
  });

  final List<FleetTableRowModel> rows;
  final List<FleetColumnDef> columns;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onEdit;
  final bool hasMore;
  final bool isLoadingMore;
  final int rowsPerPage;

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) {
      return DataRow.byIndex(
        index: index,
        cells: List<DataCell>.generate(
          columns.length,
          (cellIndex) {
            if (cellIndex == columns.length - 1 && isLoadingMore) {
              return const DataCell(Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))));
            }
            return const DataCell(SizedBox.shrink());
          },
        ),
      );
    }

    final data = rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(data.matricula, style: AppTextStyles.tableValueStrong)),
        DataCell(Text(data.marca, style: AppTextStyles.tableValue)),
        DataCell(Text(data.modelo, style: AppTextStyles.tableValue)),
        DataCell(Text(data.capacidad, style: AppTextStyles.tableValue)),
        DataCell(Text(data.largo, style: AppTextStyles.tableValue)),
        DataCell(Text(data.ancho, style: AppTextStyles.tableValue)),
        DataCell(Text(data.alto, style: AppTextStyles.tableValue)),
        DataCell(Text(data.estado, style: AppTextStyles.tableValue)),
        DataCell(Text(data.interno, style: AppTextStyles.tableValue)),
        DataCell(Text(data.matriculaRemolque, style: AppTextStyles.tableValue)),
        DataCell(Text(data.conductor, style: AppTextStyles.tableValue)),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () => onEdit?.call(data.matricula),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onDelete?.call(data.matricula),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => hasMore;

  @override
  int get rowCount => hasMore ? rows.length + rowsPerPage : rows.length;

  @override
  int get selectedRowCount => 0;
}

class _FleetVehicleCard extends StatelessWidget {
  // Esta clase se utiliza para crear tarjetas responsive para móvil
  const _FleetVehicleCard({
    required this.data,
    this.onDelete,
    this.onEdit,
  });

  final FleetTableRowModel data;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8EDF5)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.matricula, style: AppTextStyles.tableValueStrong),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onEdit?.call(data.matricula),
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => onDelete?.call(data.matricula),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _line('Marca', data.marca),
            _line('Modelo', data.modelo),
            _line('Capacidad', data.capacidad),
            _line('Dimensiones', '${data.largo} x ${data.ancho} x ${data.alto}'),
            _line('Estado', data.estado),
            _line('Interno', data.interno),
            _line('Remolque', data.matriculaRemolque),
            _line('Conductor', data.conductor),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: AppTextStyles.tableValueStrong,
          children: [TextSpan(text: value, style: AppTextStyles.tableValue)],
        ),
      ),
    );
  }
}

