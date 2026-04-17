import 'package:flutter/cupertino.dart';
import 'package:gestion_transporte/features/transportistas/ui/models/transportista_row_model.dart';

import '../../../../core/widgets/core_table/core_mobile_card.dart';
import '../../../../core/widgets/core_table/core_table.dart';
import '../../../../core/widgets/core_table/core_table_column.dart';

class TeamTable extends StatelessWidget{
  const TeamTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.selectedStatus,
    required this.statusOptions,
    required this.isMobile,
    this.onStatusChanged,
    this.onDesktopPageChanged,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onDeleteTransportista,
    this.onEditTransportista
  });

  final List<TransportistaRowModel> rows;
  final List<CoreTableColumn<TransportistaRowModel>> columns;
  final String selectedStatus;
  final List<String> statusOptions;
  final bool isMobile;
  final ValueChanged<String>? onStatusChanged;
  final ValueChanged<int>? onDesktopPageChanged;
  final bool hasMore;
  final bool isLoadingMore;
  final ValueChanged<String>? onDeleteTransportista;
  final ValueChanged<String>? onEditTransportista;

  @override
  Widget build(BuildContext context) {
    return CoreTable<TransportistaRowModel>(
      rows: rows,
      columns: columns,
      selectedStatus: selectedStatus,
      statusOptions: statusOptions,
      isMobile: isMobile,
      onStatusChanged: onStatusChanged,
      onDesktopPageChanged: onDesktopPageChanged,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      mobileCardBuilder: (transportista) => CoreMobileCard(
        title: '${transportista.nombre} ${transportista.apellido}',
        onEdit: () => onEditTransportista?.call(transportista.uid),
        onDelete: () => onDeleteTransportista?.call(transportista.uid),
        details: [
          MapEntry('Id', transportista.uid),
          MapEntry('Nombre', transportista.nombre),
          MapEntry('Email', transportista.email),
          MapEntry('Telefono', transportista.telefono),
          MapEntry('Rol', transportista.rol.join(', ')),
          MapEntry('Licencias', transportista.licencias.join(', ')),
          MapEntry('Carga asignada', transportista.cargaAsignada),
          MapEntry('Fecha de alta', transportista.fechaDeAlta),
        ],
      )
    );
  }
}