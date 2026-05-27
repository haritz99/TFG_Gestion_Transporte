import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:gestion_transporte/core/models/carga_model.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table_column.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../cargas/providers/carga_provider.dart';

class SubListadoCargas extends StatefulWidget {
  const SubListadoCargas({super.key});

  @override
  State<SubListadoCargas> createState() => _SubListadoCargasState();
}

class _SubListadoCargasState extends State<SubListadoCargas> {
  String _selectedStatus = 'Todos';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CargaProvider>();
    final cargas = provider.cargasCedidas;
    
    final filteredCargas = _selectedStatus == 'Todos'
        ? cargas
        : cargas.where((c) => c.estado.name == _selectedStatus.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargas Cedidas', style: AppTextStyles.headingMd),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: AppColors.pageBackground,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: CoreTable<CargaModel>(
                rows: filteredCargas,
                columns: _buildColumns(context),
                selectedStatus: _selectedStatus,
                statusOptions: const ['Todos', 'Pendiente', 'Asignado', 'En_transito', 'Entregado', 'Cedido'],
                isMobile: ResponsiveBreakpoints.of(context).isMobile,
                mobileCardBuilder: (carga) => _buildMobileCard(context, carga),
                onStatusChanged: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                onDesktopPageChanged: (page) {},
              ),
            ),
    );
  }

  List<CoreTableColumn<CargaModel>> _buildColumns(BuildContext context) {
    return [
      CoreTableColumn<CargaModel>(
        label: 'ID',
        cellBuilder: (carga) => Text(carga.id ?? '-', style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Origen',
        cellBuilder: (carga) => Text(carga.origen, style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Destino',
        cellBuilder: (carga) => Text(carga.destino, style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Fecha Carga',
        cellBuilder: (carga) => Text(
          DateFormat('dd/MM/yyyy HH:mm').format(carga.fechaCarga),
          style: AppTextStyles.bodyMd,
        ),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Mercancía',
        cellBuilder: (carga) => Text(carga.mercancia, style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Estado',
        cellBuilder: (carga) => Text(carga.estado.name.toUpperCase(), style: AppTextStyles.bodyMd),
      ),
    ];
  }

  Widget _buildMobileCard(BuildContext context, CargaModel carga) {
    return ListTile(
      title: Text('${carga.origen} → ${carga.destino}'),
      subtitle: Text('Mercancía: ${carga.mercancia}'),
      trailing: Text(carga.estado.name.toUpperCase()),
    );
  }
}
