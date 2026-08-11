import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../planificacion_provider.dart';
import '../../../../core/models/carga_model.dart';
import '../../../cargas/providers/carga_provider.dart';
import '../../../cargas/providers/pedido_provider.dart';

class ListaCargasPanel extends StatelessWidget {
  const ListaCargasPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanificacionProvider>();
    final pedidoProvider = context.watch<PedidoProvider>();
    final cargaProvider = context.watch<CargaProvider>();

    final pedidos = pedidoProvider.pedidos;
    final todasCargas = cargaProvider.cargas.where((c) => c.estado != EstadoCarga.cedido);
    final cargasSemanaAnterior = cargaProvider.cargasSemanaAnterior;
    final cargasPendientes = todasCargas.where((c) => c.estado == EstadoCarga.pendiente).toList();

    final Map<String, List<CargaModel>> cargasPorPedido = {};
    for (var c in cargasPendientes) {
      final pId = c.pedidoId ?? 'sin-pedido';
      cargasPorPedido.putIfAbsent(pId, () => []).add(c);
    }

    final uniquePedidoIds = cargasPorPedido.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Cargas Pendientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.titleText,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              itemCount: uniquePedidoIds.length,
              itemBuilder: (context, index) {
                final pId = uniquePedidoIds[index];
                final cargasDelPedido = cargasPorPedido[pId]!;

                final pedidoOpt = pedidos.where((p) => p.id == pId).firstOrNull;
                final title = pedidoOpt != null
                    ? '${pedidoOpt.id?.toUpperCase() ?? ''} - ${pedidoOpt.descripcion}'
                    : 'Pedido ${pId != 'sin-pedido' && pId.length > 8 ? pId.substring(0, 8).toUpperCase() : pId.toUpperCase()}';

                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    title,
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                  ),
                  children: cargasDelPedido.map((carga) => _buildCargaDraggable(context, carga, planProvider)).toList(),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (cargasSemanaAnterior.isNotEmpty) ...[
                    Text("Tienes ${cargasSemanaAnterior.length} cargas de la semana pasada sin planificar", style: AppTextStyles.bodyMd),
                    const SizedBox(height: 8),
                    _botonCargasTraerHoy(cargaProvider),
                  ],
                ]
            )
          )
        ],
      ),
    );
  }

  Widget _buildCargaDraggable(
    BuildContext context,
    CargaModel carga,
    PlanificacionProvider provider,
  ) {
    return Draggable<CargaModel>(
      data: carga,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            carga.mercancia,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCargaCard(carga, false),
      ),
      child: InkWell(
        onTap: () => provider.seleccionarCarga(carga),
        child: _buildCargaCard(
          carga,
          provider.cargaSeleccionada?.id == carga.id,
        ),
      ),
    );
  }

  Widget _buildCargaCard(CargaModel carga, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.pageBackground,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            carga.mercancia,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${carga.origen.direccion.ciudad} → ${carga.destino.direccion.ciudad}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            _detallesCarga(carga),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  String _detallesCarga(CargaModel carga) {
    final partes = <String>[];
    if (carga.peso != null) partes.add('${carga.peso}kg');
    if (carga.numBultos != null) partes.add('${carga.numBultos} bultos');
    if (carga.volumen != null) partes.add('${carga.volumen} m³');
    if (partes.isEmpty) return carga.tipoCarga.value.toUpperCase();
    return partes.join(' · ');
  }

  Widget _botonCargasTraerHoy(CargaProvider cargaProvider) {
    return TextButton(
      onPressed: () {
        cargaProvider.traerCargasEstaSemana();
      },
      style: TextButton.styleFrom(
        backgroundColor: AppColors.mutedText,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Traer a esta semana'),
    );
  }
}
