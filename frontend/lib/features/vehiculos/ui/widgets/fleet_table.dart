import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
  final List<String> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final ValueChanged<String>? onStatusChanged;

  @override
  State<FleetTable> createState() => _FleetTableState();
}

class _FleetTableState extends State<FleetTable> {
  late String _selectedStatus;

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1360,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: _VehicleDataRow(data: widget.rows[index]),
                );
              },
            ),
          ],
        ),
      ),
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
    const defaultWidths = <double>[
      130,
      120,
      170,
      100,
      80,
      80,
      80,
      105,
      95,
      170,
      190,
      120,
    ];
    final count = widget.columns.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            if (i == count - 1)
              Expanded(child: _TableHeaderCell(widget.columns[i]))
            else
              SizedBox(
                width: i < defaultWidths.length ? defaultWidths[i] : 120,
                child: _TableHeaderCell(widget.columns[i]),
              ),
        ],
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
  const _VehicleDataRow({required this.data});

  final FleetTableRowModel data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _cell(data.matricula, 130, strong: true),
        _cell(data.marca, 120),
        _cell(data.modelo, 170),
        _cell(data.capacidad, 100),
        _cell(data.largo, 80),
        _cell(data.ancho, 80),
        _cell(data.alto, 80),
        _cell(data.estado, 105),
        _cell(data.interno, 95),
        _cell(data.matriculaRemolque, 170),
        _cell(data.transportistaAsignado, 190),
        const Expanded(
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
              SizedBox(width: 12),
              Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, double width, {bool strong = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: strong ? AppTextStyles.tableValueStrong : AppTextStyles.tableValue,
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
            _line('Transportista', data.transportistaAsignado),
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


