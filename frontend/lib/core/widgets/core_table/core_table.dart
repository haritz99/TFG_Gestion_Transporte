import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../app_constants.dart';
import 'core_table_column.dart';

class CoreTable<T> extends StatefulWidget {
  const CoreTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.selectedStatus,
    required this.statusOptions,
    required this.isMobile,
    required this.mobileCardBuilder,
    this.onStatusChanged,
    required this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<T> rows;
  final List<CoreTableColumn<T>> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final Widget Function(T item) mobileCardBuilder;
  final ValueChanged<String>? onStatusChanged;
  final ValueChanged<int> onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  State<CoreTable<T>> createState() => _CoreTableState<T>();
}

class _CoreTableState<T> extends State<CoreTable<T>> {
  late String _selectedStatus;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  @override
  void didUpdateWidget(covariant CoreTable<T> oldWidget) {
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
      key: ValueKey('core_table_${widget.selectedStatus}'),
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
                '${widget.rows.length} registros',
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
        key: ValueKey('status_filter_${_selectedStatus}_${T.toString()}'),
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
                  key: ValueKey('popup_item_${status}_${T.toString()}'),
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
    final source = _CoreDesktopSource<T>(
      rows: widget.rows,
      columns: widget.columns,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
    );

    return LayoutBuilder(
      key: ValueKey('desktop_table_$_selectedStatus'),
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 1350 ? constraints.maxWidth : 1350.0;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Theme(
                data: Theme.of(context).copyWith(
                  cardColor: Colors.white,
                  cardTheme: const CardThemeData(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                  ),
                  dividerColor: const Color(0xFFE8EDF5),
                ),
                child: PaginatedDataTable(
                  columns: widget.columns
                      .map((col) => DataColumn(label: Text(col.label, style: AppTextStyles.tableHeader)))
                      .toList(),
                  source: source,
                  showCheckboxColumn: false,
                  rowsPerPage: AppConstants.paginationPageSize,
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
        return widget.mobileCardBuilder(widget.rows[index]);
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

class _CoreDesktopSource<T> extends DataTableSource {
  _CoreDesktopSource({
    required this.rows,
    required this.columns,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<T> rows;
  final List<CoreTableColumn<T>> columns;
  final bool hasMore;
  final bool isLoadingMore;

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
      cells: columns.map((col) => DataCell(col.cellBuilder(data))).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => hasMore;

  @override
  int get rowCount => hasMore ? rows.length + AppConstants.paginationPageSize : rows.length;

  @override
  int get selectedRowCount => 0;
}