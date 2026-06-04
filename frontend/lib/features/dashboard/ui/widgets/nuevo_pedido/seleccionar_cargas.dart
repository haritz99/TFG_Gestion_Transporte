import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../../core/models/vehiculo_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../cargas/providers/pedido_provider.dart';
import '../../../../transportistas/providers/transportista_provider.dart';
import '../../../../vehiculos/providers/vehiculo_provider.dart';

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
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final transportistaProvider = context.watch<TransportistaProvider>();

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

              final conductorValido = transportistaProvider.transportistasDisponibles
                  .contains(asig.conductor) ? asig.conductor : null;

              final vehiculoValido = vehiculoProvider.vehiculosDisponibles
                  .contains(asig.vehiculo) ? asig.vehiculo : null;

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
                                ...transportistaProvider.transportistasDisponibles.map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t.nombre, overflow: TextOverflow.ellipsis))),
                              ],
                              // Sin cargaIdx
                              onChanged: (v) => context
                                  .read<PedidoProvider>()
                                  .asignarConductor(unidadIdx, v),
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
                                ...vehiculoProvider.vehiculosDisponibles.map((v) =>
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