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
  });

  final List<FleetTableRowModel> rows;
  final List<FleetColumnDef> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final ValueChanged<String>? onStatusChanged;

  @override
  State<FleetTable> createState() => _FleetTableState();
}

class _FleetTableState extends State<FleetTable> {
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
                '${widget.rows.length} vehiculos',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth = constraints.maxWidth > 1300 ? constraints.maxWidth : 1300;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _buildColumnsHeader(),
                  const Divider(height: 1, color: Color(0xFFE8EDF5)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.rows.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: Color(0xFFF0F3F8),
                    ),
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: _VehicleDataRow(
                          data: widget.rows[index],
                          columns: widget.columns,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCards() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF0F3F8)),
      itemBuilder: (_, index) => _FleetVehicleCard(data: widget.rows[index]),
    );
  }

  Widget _buildColumnsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: widget.columns.map((col) {
          return Expanded(
            flex: col.flex,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _TableHeaderCell(col.label),
            ),
          );
        }).toList(),
      ),
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

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.tableHeader, overflow: TextOverflow.ellipsis);
  }
}

class _VehicleDataRow extends StatelessWidget {
  const _VehicleDataRow({
    required this.data,
    required this.columns,
  });

  final FleetTableRowModel data;
  final List<FleetColumnDef> columns;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _flexCell(data.matricula, columns[0].flex, strong: true),
        _flexCell(data.marca, columns[1].flex),
        _flexCell(data.modelo, columns[2].flex),
        _flexCell(data.capacidad, columns[3].flex),
        _flexCell(data.largo, columns[4].flex),
        _flexCell(data.ancho, columns[5].flex),
        _flexCell(data.alto, columns[6].flex),
        _flexCell(data.estado, columns[7].flex),
        _flexCell(data.interno, columns[8].flex),
        _flexCell(data.matriculaRemolque, columns[9].flex),
        _flexCell(data.conductor, columns[10].flex),
        Expanded(
          flex: columns[11].flex,
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
              SizedBox(width: 12),
              Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _flexCell(String text, int flex, {bool strong = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: strong ? AppTextStyles.tableValueStrong : AppTextStyles.tableValue,
        ),
      ),
    );
  }
}

class _FleetVehicleCard extends StatelessWidget {
  const _FleetVehicleCard({required this.data});

  final FleetTableRowModel data;

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
                  children: const [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
                    SizedBox(width: 12),
                    Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
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
