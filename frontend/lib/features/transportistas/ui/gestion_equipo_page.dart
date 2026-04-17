import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/transportistas/ui/widgets/team_kpi_grid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/core_table/core_table_column.dart';
import '../../../core/widgets/management_page_layout.dart';
import './models/transportista_row_model.dart';
import 'widgets/team_table.dart';
import 'widgets/team_header.dart';

class GestionEquipoPage extends StatefulWidget {
  const GestionEquipoPage({
    super.key,
    this.totalEquipo,
    this.enRuta,
    this.disponibles,
    this.inactivos,
    this.selectedStatus = 'Todos',
    this.statusOptions = const [
      'Todos',
      'En Ruta',
      'Activo',
      'Disponible',
    ],
    this.columns = const [
      CoreTableColumn<TransportistaRowModel>(label: 'ID', flex: 10, cellBuilder: _buildIdCell),
      CoreTableColumn<TransportistaRowModel>(label: 'NOMBRE', flex: 20, cellBuilder: _buildNombreCell),
      CoreTableColumn<TransportistaRowModel>(label: 'ROL', flex: 15, cellBuilder: _buildRolCell),
      CoreTableColumn<TransportistaRowModel>(label: 'LICENCIA', flex: 10, cellBuilder: _buildLicenciaCell),
      CoreTableColumn<TransportistaRowModel>(label: 'TELÉFONO', flex: 15, cellBuilder: _buildTelefonoCell),
      CoreTableColumn<TransportistaRowModel>(label: 'ESTADO', flex: 12, cellBuilder: _buildEstadoCell),
      CoreTableColumn<TransportistaRowModel>(label: 'CARGA ASIGNADA', flex: 10, cellBuilder: _buildCargasCell),
      CoreTableColumn<TransportistaRowModel>(label: 'ALTA', flex: 12, cellBuilder: _buildAltaCell),
    ],
    this.rows = const [],
    this.onStatusChanged,
    this.onAddMiembro,
    this.onDeleteMiembro,
    this.onEditMiembro,
    this.onMobileLoadMore,
    this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final int? totalEquipo;
  final int? enRuta;
  final int? disponibles;
  final int? inactivos;

  final String selectedStatus;
  final List<String> statusOptions;

  final List<CoreTableColumn<TransportistaRowModel>> columns;
  final List<TransportistaRowModel> rows;

  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onAddMiembro;
  final ValueChanged<String>? onDeleteMiembro;
  final ValueChanged<String>? onEditMiembro;
  final Future<void> Function()? onMobileLoadMore;
  final ValueChanged<int>? onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  State<GestionEquipoPage> createState() => _GestionEquipoPageState();
}

class _GestionEquipoPageState extends State<GestionEquipoPage> {
  @override
  Widget build(BuildContext context) {
    final tableColumns = [
      ...widget.columns,
      CoreTableColumn<TransportistaRowModel>(
        label: 'ACCIONES',
        flex: 12,
        cellBuilder: (item) => Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
              onPressed: () => widget.onEditMiembro?.call(item.uid),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
              onPressed: () => widget.onDeleteMiembro?.call(item.uid),
            ),
          ],
        ),
      ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 900;

    return ManagementPageLayout(
      header: TeamHeader(
        onAddMiembro: widget.onAddMiembro,
        isMobile: isMobile,
      ),
      kpiGrid: TeamKpiGrid(
        totalEquipo: widget.totalEquipo,
        enRuta: widget.enRuta,
        disponibles: widget.disponibles,
        inactivos: widget.inactivos, 
        isMobile: isMobile,
      ),
      table: TeamTable(
        rows: widget.rows,
        columns: tableColumns,
        selectedStatus: widget.selectedStatus,
        statusOptions: widget.statusOptions,
        onStatusChanged: widget.onStatusChanged,
        onDeleteTransportista: widget.onDeleteMiembro,
        onEditTransportista: widget.onEditMiembro,
        isMobile: isMobile,
        hasMore: widget.hasMore,
        isLoadingMore: widget.isLoadingMore,
        onDesktopPageChanged: widget.onDesktopPageChanged,
      ),
      onMobileLoadMore: widget.onMobileLoadMore,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
      isMobile: isMobile,
    );
  }
  
}

Widget _buildIdCell(TransportistaRowModel item) => Text(item.uid.substring(0, 6), style: AppTextStyles.tableValue);
Widget _buildNombreCell(TransportistaRowModel item) => Row(
  children: [
    CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary.withAlpha(30),
      child: Text(item.nombre[0], style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
    ),
    const SizedBox(width: 8),
    Text('${item.nombre} ${item.apellido}', style: AppTextStyles.tableValueStrong),
  ],
);
Widget _buildRolCell(TransportistaRowModel item) => Text(item.rol.join(', '), style: AppTextStyles.tableValue);
Widget _buildLicenciaCell(TransportistaRowModel item) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
  child: Text(item.licencias.isNotEmpty ? item.licencias.first : '-', style: AppTextStyles.tableValue),
);
Widget _buildTelefonoCell(TransportistaRowModel item) => Text(item.telefono, style: AppTextStyles.tableValue);
Widget _buildEstadoCell(TransportistaRowModel item) => Text(item.estado, style: AppTextStyles.tableValue);
Widget _buildCargasCell(TransportistaRowModel item) => Text(item.cargaAsignada, style: AppTextStyles.tableValue);
Widget _buildAltaCell(TransportistaRowModel item) => Text(item.fechaDeAlta, style: AppTextStyles.tableValue);

