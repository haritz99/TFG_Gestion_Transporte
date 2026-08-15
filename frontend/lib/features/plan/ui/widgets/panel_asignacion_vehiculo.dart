import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/carga_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../planificacion_provider.dart';
import '../../../transportistas/transportista_provider.dart';
import '../../../vehiculos/vehiculo_provider.dart';
import '../../../cargas/providers/carga_provider.dart';
import '../../../dashboard/providers/invite_provider.dart';
import 'buffer_selector.dart';

class PanelAsignacionVehiculo extends StatelessWidget {
  const PanelAsignacionVehiculo({super.key});

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanificacionProvider>();
    final cargaProvider = context.watch<CargaProvider>();

    final seleccionId = planProvider.cargaSeleccionada?.id;
    final carga = seleccionId != null
        ? cargaProvider.cargas.where((c) => c.id == seleccionId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: carga != null
          ? _DetallesAsignacionContent(carga: carga)
          : const Center(child: Text('No hay cargas seleccionadas'))
    );
  }

}

class _DetallesAsignacionContent extends StatelessWidget {
  final CargaModel carga;
  const _DetallesAsignacionContent({required this.carga});

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanificacionProvider>();
    final cargaProvider = context.watch<CargaProvider>();
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final transportistaProvider = context.watch<TransportistaProvider>();
    final inviteProvider = context.watch<InviteProvider>();

    final bufferGlobal = context.watch<AuthProvider>().company?.companyBuffer ?? 0;
    final currentBuffer = carga.bufferHours ?? bufferGlobal;

    final subcontratados = inviteProvider.guests
        .where((guest) => guest.rol.any((r) => r.toLowerCase().contains('subcontratado')))
        .toList();

    final conductoresDisponibles = cargaProvider.conductoresDisponibles(
      todosLosConductores: transportistaProvider.transportistas,
      fechaInicioTarget: carga.fechaCarga,
      fechaFinTarget: carga.fechaDescarga,
      companyDefaultBuffer: bufferGlobal,
      targetBufferOverride: carga.bufferHours,
    );

    if (carga.transportistaId != null && !conductoresDisponibles.any((t) => t.uid == carga.transportistaId)) {
      final actual = transportistaProvider.transportistas
          .where((t) => t.uid == carga.transportistaId)
          .firstOrNull;
      if (actual != null) {
        conductoresDisponibles.insert(0, actual);
      }
    }

    final vehiculosDisponibles = cargaProvider.vehiculosDisponibles(
      todosLosVehiculos: vehiculoProvider.vehiculos,
      fechaInicioTarget: carga.fechaCarga,
      fechaFinTarget: carga.fechaDescarga,
      companyDefaultBuffer: bufferGlobal,
      targetBufferOverride: carga.bufferHours,
    );

    if (carga.vehiculoId != null && !vehiculosDisponibles.any((v) => v.matricula == carga.vehiculoId)) {
      final actual = vehiculoProvider.vehiculos
          .where((v) => v.matricula == carga.vehiculoId)
          .firstOrNull;
      if (actual != null) {
        vehiculosDisponibles.insert(0, actual);
      }
    }

    final puedeGenerarCarta = carga.transportistaId != null && carga.vehiculoId != null;

    if (carga.estado == EstadoCarga.cedido) {
      return _panelCedido(context, cargaProvider);
    }

    return ListView(
      key: ValueKey('panel_list_${carga.id}'),
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
                Text('${carga.origen.direccion.ciudad} → ${carga.destino.direccion.ciudad}', style: AppTextStyles.bodySm),
                if (carga.peso != null) Text('Peso: ${carga.peso}kg', style: AppTextStyles.bodySm),
                if (carga.longitudLineal != null) Text('Longitud lineal: ${carga.longitudLineal}m', style: AppTextStyles.bodySm),
             ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Conductor Asignado', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDropdown<String?>(
          key: ValueKey('dropdown_conductor_${carga.id}'),
          initialValue: carga.transportistaId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin asignar')),
            ...conductoresDisponibles.map((t) =>
                DropdownMenuItem(value: t.uid, child: Text(
                    '${t.nombre} ${t.apellido}'.trim(),
                    overflow: TextOverflow.ellipsis,
                ),
                )),
          ],
          onChanged: (id) {
            final t = conductoresDisponibles.where((x) => x.uid == id).firstOrNull;
            final nombreCompleto = t != null ? '${t.nombre} ${t.apellido}'.trim() : null;
            cargaProvider.asignarConductor(carga.id!, id, nombreCompleto);
          },
        ),
        const SizedBox(height: 24),
        Text('Vehículo Asignado', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDropdown<String?>(
          key: ValueKey('dropdown_vehiculo_${carga.id}'),
          initialValue: carga.vehiculoId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin asignar')),
            ...vehiculosDisponibles.map((v) =>
                DropdownMenuItem(value: v.matricula, child: Text(v.matricula))),
          ],
          onChanged: (matricula) => cargaProvider.asignarVehiculo(carga.id!, matricula),
        ),
        const SizedBox(height: 24),
        BufferSelector(
          title: 'Tiempo de retorno',
          value: currentBuffer,
          onChanged: (nuevoValor) {
            context.read<CargaProvider>().actualizarBufferHours(carga.id!, nuevoValor);
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
           onPressed: puedeGenerarCarta ? () => _generarCartaPorte(context, carga, cargaProvider) : null,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child:  _buildDropdown<String?>(
                key: ValueKey('dropdown_sub_${carga.id}'),
                initialValue: subcontratados.any((s) => s.uid == planProvider.subcontratadoSeleccionadoId)
                    ? planProvider.subcontratadoSeleccionadoId
                    : null,
                items: [
                  const DropdownMenuItem(value: null, child: Text('---- Seleccionar Subcontratado ---')),
                  ...subcontratados.map((guest) => DropdownMenuItem(
                    value: guest.uid,
                    child: Text(guest.nombre, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: planProvider.seleccionarSubcontratado,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: 'Comisión',
                  suffixIcon: PopupMenuButton<double>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: planProvider.seleccionarComision,
                    itemBuilder: (context) => [3.0, 5.0, 10.0].map((c) =>
                        PopupMenuItem(value: c, child: Text('${c.toStringAsFixed(0)}%'))
                    ).toList(),
                  ),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed <= 100) {
                    planProvider.seleccionarComision(parsed.toDouble());
                  }
                },
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: (planProvider.subcontratadoSeleccionadoId == null || carga.id == null)
              ? null
              : () => _cederCarga(context, carga.id!, cargaProvider, planProvider.subcontratadoSeleccionadoId),
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Ceder carga a Subcontratado'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

Widget _panelCedido(BuildContext context, CargaProvider cargaProvider) {
    final nombreSubcontratado = carga.cartaPorteSnapshot?.subcontratadoNombre;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Carga cedida', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary.withValues(alpha: 0.8))),
        const SizedBox(height: 12),
        Text('Esta carga ha sido cedida a $nombreSubcontratado.', style: AppTextStyles.bodySm),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => _generarCartaPorte(context, carga, cargaProvider),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Generar Carta de Porte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _confirmarRevertirCesion(context, cargaProvider),
          icon: const Icon(Icons.replay),
          label: const Text('Revertir cesión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )
      ]
    );
  }

  Future<void> _confirmarRevertirCesion(BuildContext context, CargaProvider cargaProvider) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revertir cesión'),
        content: Text(
          '¿Seguro que quieres revertir la cesión de la carga ${carga.id}? '
          'Volverá al estado planificado y se eliminará la carta de porte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    try {
      await cargaProvider.descenderCarga(carga.id!);
      if (!context.mounted) return;
      context.read<PlanificacionProvider>().limpiarSeleccion();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al revertir la cesión: $e')),
      );
    }
  }

  Future<void> _generarCartaPorte(BuildContext context, CargaModel carga, CargaProvider cargaProvider) async {
    await cargaProvider.generarCartaDePorte(carga.id!);
    if (!context.mounted) return;
    final msg = cargaProvider.errorMessage ?? 'Carta de porte generada correctamente';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDropdown<T>({
    Key? key,
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: key,
      isExpanded: true,
      initialValue: initialValue,
      decoration: _decoration,
      items: items,
      onChanged: onChanged,
    );
  }

  InputDecoration get _decoration => InputDecoration(
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
