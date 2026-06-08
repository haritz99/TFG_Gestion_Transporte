import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:gestion_transporte/core/models/pedido_model.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table_column.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/nuevo_pedido/form_builder.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../cargas/providers/pedido_provider.dart';

class CargadorListaPedidos extends StatefulWidget {

  const CargadorListaPedidos({super.key});

  @override
  State<CargadorListaPedidos> createState() => _CargadorListaPedidosState();
}

class _CargadorListaPedidosState extends State<CargadorListaPedidos> {
  String _selectedStatus = 'Todos';

  void _showEditDialog(BuildContext context, PedidoModel pedido) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FormBuilderPedido(pedidoParaEditar: pedido),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = context.watch<PedidoProvider>().pedidosFiltrados(_selectedStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos', style: AppTextStyles.headingMd),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CoreTable<PedidoModel>(
          rows: pedidos,
          columns: _buildColumns(context),
          selectedStatus: _selectedStatus,
          statusOptions: const ['Todos', 'Planificado', 'En Curso', 'Completado'],
          isMobile: ResponsiveBreakpoints.of(context).isMobile,
          mobileCardBuilder: (pedido) => _buildMobileCard(context, pedido),
          onStatusChanged: (status) => setState(() => _selectedStatus = status),
          onDesktopPageChanged: (_) {},
        ),
      ),
    );
  }

  List<CoreTableColumn<PedidoModel>> _buildColumns(BuildContext context) {
    return [
      CoreTableColumn(label: 'ID / Ref', cellBuilder: (p) => Text(p.id ?? '-', style: AppTextStyles.bodyMd)),
      CoreTableColumn(label: 'Descripción', cellBuilder: (p) => Text(p.descripcion ?? '', style: AppTextStyles.bodyMd)),
      CoreTableColumn(label: 'Fecha de carga', cellBuilder: (p) => Text(DateFormat('dd/MM/yyyy HH:mm').format(p.fechaCarga), style: AppTextStyles.bodyMd)),
      CoreTableColumn(label: 'Fecha límite', cellBuilder: (p) => Text(DateFormat('dd/MM/yyyy HH:mm').format(p.fechaDescarga), style: AppTextStyles.bodyMd)),
      CoreTableColumn(label: 'Estado', cellBuilder: (p) => Text(p.estado.name.toUpperCase(), style: AppTextStyles.bodyMd)),
      CoreTableColumn(label: 'Acciones', cellBuilder: (p) => IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(context, p))),
    ];
  }

  Widget _buildMobileCard(BuildContext context, PedidoModel pedido) {
    return ListTile(
      title: Text('Ref: ${pedido.id ?? "-"}'),
      subtitle: Text(pedido.descripcion ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: () => _showEditDialog(context, pedido),
      ),
    );
  }
}
