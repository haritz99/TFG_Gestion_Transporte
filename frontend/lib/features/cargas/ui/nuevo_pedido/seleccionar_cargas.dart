import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/cargas/providers/carga_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/vehiculo_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/pedido_provider.dart';
import '../../../transportistas/transportista_provider.dart';
import '../../../vehiculos/vehiculo_provider.dart';

class SeleccionarCargasForm extends StatefulWidget {
  const SeleccionarCargasForm({super.key});
  @override
  State<SeleccionarCargasForm> createState() => SeleccionarCargasFormState();
}

class SeleccionarCargasFormState extends State<SeleccionarCargasForm> {
  bool validate() => context.read<PedidoProvider>().cargasDelPedido != null;

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();
    final todosConductores = context.watch<TransportistaProvider>().transportistas;
    final todosVehiculos = context.watch<VehiculoProvider>().vehiculos;
    final cargaProvider = context.watch<CargaProvider>();
    final companyBuffer = context.read<AuthProvider>().company?.companyBuffer ?? 0;

    final seleccion = pedidoProvider.cargasDelPedido;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (seleccion != null)
          ExpansionTile(
            title: Text(
              '${seleccion.tipo.mercancia} · ${seleccion.tipo.precio}€/ud · '
                  'Total: ${seleccion.subtotal.toStringAsFixed(2)}€',
            ),
            initiallyExpanded: true,
            children: List.generate(seleccion.cantidad, (unidadIdx) {
              final asig = seleccion.asignaciones[unidadIdx];
              final fechaInicio = asig.fechaCarga ?? DateTime.now();
              final fechaFin = asig.fechaLimite ?? fechaInicio.add(const Duration(hours: 5));

              final conductoresDisponibles = cargaProvider.conductoresDisponibles(
                todosLosConductores: todosConductores,
                fechaInicioTarget: fechaInicio,
                fechaFinTarget: fechaFin,
                companyDefaultBuffer: companyBuffer,
              );

              final vehiculosDisponibles = cargaProvider.vehiculosDisponibles(
                todosLosVehiculos: todosVehiculos,
                fechaInicioTarget: fechaInicio,
                fechaFinTarget: fechaFin,
                companyDefaultBuffer: companyBuffer,
              );

              final conductorValido = conductoresDisponibles.contains(asig.conductor) ? asig.conductor : null;

              final vehiculoValido = vehiculosDisponibles.contains(asig.vehiculo) ? asig.vehiculo : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unidad ${unidadIdx + 1}',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<UserModel?>(
                              isExpanded: true,
                              initialValue: conductorValido,
                              decoration: _inputDecoration().copyWith(labelText: 'Conductor'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                                ...conductoresDisponibles.map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t.nombre, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (v) => context.read<PedidoProvider>().asignarConductor(unidadIdx, v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<VehiculoModel?>(
                              isExpanded: true,
                              initialValue: vehiculoValido,
                              decoration: _inputDecoration().copyWith(labelText: 'Vehículo'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                                ...vehiculosDisponibles.map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v.matricula))),
                              ],
                              onChanged: (v) => context
                                  .read<PedidoProvider>()
                                  .asignarVehiculo(unidadIdx, v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

        if (seleccion != null) ...[
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precio total:', style: AppTextStyles.headingMd),
              Text('${pedidoProvider.precioTotal.toStringAsFixed(2)} €',
                  style: AppTextStyles.headingMd),
            ],
          ),
        ],
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
}