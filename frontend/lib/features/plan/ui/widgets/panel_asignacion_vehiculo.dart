import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/planificacion_provider.dart';
import '../../../transportistas/providers/transportista_provider.dart';
import '../../../vehiculos/providers/vehiculo_provider.dart';
import '../../../cargas/providers/carga_provider.dart';
import '../../../dashboard/providers/invite_provider.dart';

class PanelAsignacionVehiculo extends StatelessWidget {
  const PanelAsignacionVehiculo({super.key});

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanificacionProvider>();
    final cargaProvider = context.watch<CargaProvider>();

    // Buscar la carga actualizada en CargaProvider por si cambió algo
    final seleccionId = planProvider.cargaSeleccionada?.id;
    final seleccion = seleccionId != null
        ? cargaProvider.cargas.firstWhere((c) => c.id == seleccionId) : null;

    final hasSelection = seleccion != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: hasSelection
          ? _buildDetailsPanel(context, planProvider)
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.border,
          ),
          SizedBox(height: 16),
          Text(
            'Selecciona una carga',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Haz clic en una carga del calendario para\nver y gestionar su asignación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, PlanificacionProvider planProvider) {
    final cargaProvider = context.read<CargaProvider>();
    final selecionId = planProvider.cargaSeleccionada?.id;
    final carga = cargaProvider.cargas.firstWhere((c) => c.id == selecionId);

    final vehiculoProvider = context.watch<VehiculoProvider>();
    final transportistaProvider = context.watch<TransportistaProvider>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detalles de Asignación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.titleText,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => planProvider.limpiarSeleccion(),
            )
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text(
                  '${carga.id?.toUpperCase()} - ${carga.mercancia}',
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${carga.origen} → ${carga.destino}', style: AppTextStyles.bodySm),
                Text('Peso: ${carga.peso}t', style: AppTextStyles.bodySm),
             ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Conductor Asignado', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: carga.transportistaId,
          decoration: _inputDecoration(),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin asignar')),
            ...transportistaProvider.transportistasDisponibles.map((t) =>
                DropdownMenuItem(value: t.uid, child: Text(t.nombre, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (id) {
            final t = transportistaProvider.transportistasDisponibles.where((x) => x.uid == id).firstOrNull;
            cargaProvider.asignarConductor(carga.id!, id, t?.nombre);
          },
        ),
        const SizedBox(height: 24),
        Text('Vehículo Asignado', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: carga.vehiculoId,
          decoration: _inputDecoration(),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin asignar')),
            ...vehiculoProvider.vehiculosDisponibles.map((v) =>
                DropdownMenuItem(value: v.matricula, child: Text(v.matricula))),
          ],
          onChanged: (matricula) => cargaProvider.asignarVehiculo(carga.id!, matricula),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
           onPressed: (carga.transportistaId != null && carga.vehiculoId != null)
              ? () { /* TODO: Generar carta de porte */ }
              : null,
           icon: const Icon(Icons.description_outlined),
           label: const Text('Generar Carta de Porte'),
           style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
        ),

        const Divider(height: 32),
        Text('Ceder carga (Opcional)', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: planProvider.subcontratadoSeleccionadoId,
          decoration: _inputDecoration(),
          items: [
            const DropdownMenuItem(value: null, child: Text('---- Seleccionar Subcontratado ---')),
            ...context.watch<InviteProvider>().guests
                .where((guest) => guest.rol.contains('subcontratado'))
                .map((guest) => DropdownMenuItem(
                      value: guest.uid,
                      child: Text(guest.nombre, overflow: TextOverflow.ellipsis),
                    )),
          ],
          onChanged: planProvider.seleccionarSubcontratado,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: (planProvider.subcontratadoSeleccionadoId == null || carga.id == null)
              ? null
              : () => _cederCarga(context, carga.id!, cargaProvider, planProvider.subcontratadoSeleccionadoId),
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Ceder carga a Subcontratados'),

        ),
      ],
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary)),
  );

  Future<void> _cederCarga(BuildContext context, String cargaId, CargaProvider cargaProvider, String? subId) async {
    try {
      await cargaProvider.cederCargaASubcontratado(cargaId: cargaId, subcontratadoId: subId!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carga cedida al subcontratado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al ceder la carga: $e')),
      );
    }
  }
}
