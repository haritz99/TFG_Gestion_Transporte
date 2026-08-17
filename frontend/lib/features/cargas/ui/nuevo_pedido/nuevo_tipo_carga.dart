import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/carga_provider.dart';
import '../form_campos_carga.dart';

class NuevoTipoCarga extends StatefulWidget {
  final ExternalUserModel cliente;
  const NuevoTipoCarga({super.key, required this.cliente});

  @override
  State<NuevoTipoCarga> createState() => _NuevoTipoCargaState();
}

class _NuevoTipoCargaState extends State<NuevoTipoCarga> {
  final _formKey = GlobalKey<FormState>();
  final _camposCargaKey = GlobalKey<FormCamposCargaState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _pesoMaxController = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _pesoMaxController.dispose();
    super.dispose();
  }

  double? _toDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  Future<void> _guardar() async {
    final camposState = _camposCargaKey.currentState;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!(camposState?.validate() ?? false)) return;

    setState(() => _guardando = true);

    final campos = camposState!.datos;
    final nuevoTipo = TipoCargaModel(
      id: '',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      mercancia: campos.mercancia,
      tipoEmbalaje: campos.tipoEmbalaje,
      tipoCarga: campos.tipoCarga,
      numBultos: campos.numBultos,
      peso: campos.peso,
      pesoMax: _toDouble(_pesoMaxController.text),
      precio: campos.precio,
      apilable: campos.apilable,
      volumen: campos.volumen,
      largo: campos.largo,
      ancho: campos.ancho,
      alto: campos.alto,
      origen: campos.origen,
      destino: campos.destino,
      clienteId: widget.cliente.uid,
      companyId: widget.cliente.companyId,
    );

    try {
      final creado = await context.read<CargaProvider>().crearTipoCarga(nuevoTipo);
      if (mounted) Navigator.pop(context, creado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el tipo de carga: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nuevo tipo de carga',
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.titleText)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: FormCamposCargaState.validatorRequerido,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FormCamposCarga(key: _camposCargaKey),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pesoMaxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso máx. (kg)', border: OutlineInputBorder()),
                    validator: FormCamposCargaState.validatorOpcionalPositivo,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _guardando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: _guardando
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ) : const Text('Crear', style: AppTextStyles.buttonSmall),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}