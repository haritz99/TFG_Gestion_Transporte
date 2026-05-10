import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/carga_model.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../../core/models/vehiculo_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../cargas/providers/carga_provider.dart';
import '../../../../cargas/providers/pedido_provider.dart';
import '../../../../transportistas/providers/transportista_provider.dart';
import '../../../../vehiculos/providers/vehiculo_provider.dart';

class SeleccionarCargasForm extends StatefulWidget {
  const SeleccionarCargasForm({super.key});
  @override
  State<SeleccionarCargasForm> createState() => SeleccionarCargasFormState();
}

class SeleccionarCargasFormState extends State<SeleccionarCargasForm> {
  TipoCargaModel? _selectedTipo;
  int _cantidad = 1;

  bool validate() => context.read<PedidoProvider>().cargasDelPedido != null;

  void _addCarga() {
    if (_selectedTipo == null) return;
    context.read<PedidoProvider>().anadirCarga(_selectedTipo!, _cantidad);
    setState(() {
      _selectedTipo = null;
      _cantidad = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cargaProvider = context.watch<CargaProvider>();
    final pedidoProvider = context.watch<PedidoProvider>();
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final transportistaProvider = context.watch<TransportistaProvider>();

    final seleccion = pedidoProvider.cargasDelPedido;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<TipoCargaModel>(
                initialValue: _selectedTipo,
                hint: const Text('Tipo de carga'),
                decoration: _inputDecoration(),
                isExpanded: true,
                itemHeight: 56,
                items: cargaProvider.tiposCarga.map((c) => DropdownMenuItem(
                  value: c,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.nombre, style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedTipo = v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                key: ValueKey(_cantidad),
                initialValue: _cantidad.toString(),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration().copyWith(labelText: 'Cant.'),
                onChanged: (v) => setState(() => _cantidad = int.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _selectedTipo != null ? _addCarga : null,
              child: const Text('Añadir', style: AppTextStyles.buttonSmall),
            ),
          ],
        ),

        if (_selectedTipo != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(_selectedTipo!.descripcion ?? '', style: AppTextStyles.bodySm),
                const SizedBox(height: 8),
                Text('${_selectedTipo!.precio}€/ud', style: AppTextStyles.bodySm),
                const SizedBox(height: 8),
                Text('Origen: ${_selectedTipo!.origen} - Destino: ${_selectedTipo!.destino}', style: AppTextStyles.bodySm),
              ],
            ),
          ),

        const SizedBox(height: 24),

        if (seleccion != null)
          ExpansionTile(
            title: Text(
              '${seleccion.tipo.mercancia} · ${seleccion.tipo.precio}€/ud · '
                  'Total: ${seleccion.subtotal.toStringAsFixed(2)}€',
            ),
            initiallyExpanded: true,
            children: List.generate(seleccion.cantidad, (unidadIdx) {
              final asig = seleccion.asignaciones[unidadIdx];
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
                              initialValue: asig.conductor,
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
                              initialValue: asig.vehiculo,
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