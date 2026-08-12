import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/carga_model.dart';
import '../../../../../core/models/direccion_model.dart';
import '../../../../../core/services/ubicacion_search_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../cargas/providers/carga_provider.dart';

class NuevoTipoCarga extends StatefulWidget {
  final ExternalUserModel cliente;
  const NuevoTipoCarga({super.key, required this.cliente});

  @override
  State<NuevoTipoCarga> createState() => _NuevoTipoCargaState();
}

class _NuevoTipoCargaState extends State<NuevoTipoCarga> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _mercanciaController = TextEditingController();
  final _tipoEmbalajeController = TextEditingController();
  final _numBultosController = TextEditingController();
  final _pesoController = TextEditingController();
  final _pesoMaxController = TextEditingController();
  final _precioController = TextEditingController();
  final _volumenController = TextEditingController();
  final _largoController = TextEditingController();
  final _anchoController = TextEditingController();
  final _altoController = TextEditingController();
  final _origenUbicacion = UbicacionControllers();
  final _destinoUbicacion = UbicacionControllers();

  bool _guardando = false;
  TipoCarga _tipoDeCarga = TipoCarga.bultos;
  bool _apilable = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _mercanciaController.dispose();
    _tipoEmbalajeController.dispose();
    _numBultosController.dispose();
    _pesoController.dispose();
    _pesoMaxController.dispose();
    _precioController.dispose();
    _volumenController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _origenUbicacion.dispose();
    _destinoUbicacion.dispose();
    super.dispose();
  }


  String? _validatorRequerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    return null;
  }

  String? _validatorOpcionalPositivo(String? value, {bool entero = false}) {
    if (value == null || value.trim().isEmpty) return null;
    final texto = value.trim();
    if (entero) {
      final n = int.tryParse(texto);
      if (n == null || n <= 0) return 'Debe ser un entero mayor que 0';
    } else {
      final n = double.tryParse(texto.replaceAll(',', '.'));
      if (n == null || n <= 0) return 'Debe ser mayor que 0';
    }
    return null;
  }

  double? _toDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);

    final nuevoTipo = TipoCargaModel(
      id: '',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      mercancia: _mercanciaController.text.trim(),
      tipoEmbalaje: _tipoEmbalajeController.text.trim().isEmpty ? null : _tipoEmbalajeController.text.trim(),
      tipoCarga: TipoCarga.fromString(_tipoDeCarga.value),
      numBultos: int.tryParse(_numBultosController.text.trim()),
      peso: _toDouble(_pesoController.text),
      pesoMax: _toDouble(_pesoMaxController.text),
      precio: _toDouble(_precioController.text) ?? 0,
      apilable: _apilable,
      volumen: _toDouble(_volumenController.text),
      largo: _toDouble(_largoController.text),
      ancho: _toDouble(_anchoController.text),
      alto: _toDouble(_altoController.text),
      origen: _origenUbicacion.toModel(),
      destino: _destinoUbicacion.toModel(),
      clienteId: widget.cliente.uid,
      companyId: widget.cliente.companyId
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

  Widget _campoNumero(TextEditingController controller, String label, String? Function(String?)? validator) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: validator,
    );
  }

  Widget _seccionUbicacion({required String titulo, required UbicacionControllers controllers}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
        const SizedBox(height: 8),
        Autocomplete<SugerenciaDireccion>(
            optionsBuilder: (TextEditingValue value) async {
              if (value.text.trim().length < 3) return const [];
              return buscarDirecciones(value.text);
            },
            displayStringForOption: (option) => option.etiqueta,
            onSelected: (option) {
              setState(() => controllers.aplicarSugerencia(option));
            },
          fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Buscar dirección',
                hintText: 'Escribe al menos 3 letras...',
                border: OutlineInputBorder(),
              ),
            );
          },
        )
      ],
    );
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
                    validator: _validatorRequerido,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mercanciaController,
                    decoration: const InputDecoration(labelText: 'Mercancía', border: OutlineInputBorder()),
                    validator: _validatorRequerido,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoDeCarga.value,
                    items: const [
                      DropdownMenuItem(value: 'bultos', child: Text('Bultos')),
                      DropdownMenuItem(value: 'granel', child: Text('Granel')),
                      DropdownMenuItem(value: 'liquido', child: Text('Líquido')),
                    ],
                    decoration: const InputDecoration(labelText: 'Tipo de carga', border: OutlineInputBorder()),
                    validator: _validatorRequerido,
                    onChanged: (String? value) {
                      setState(() {
                        _tipoDeCarga = TipoCarga.fromString(value ?? 'bultos');
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tipoEmbalajeController,
                    decoration: const InputDecoration(labelText: 'Tipo de embalaje', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  _seccionUbicacion(titulo: 'Origen', controllers: _origenUbicacion),
                  const SizedBox(height: 4),
                  _seccionUbicacion(titulo: 'Destino', controllers: _destinoUbicacion),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _campoNumero(_pesoController, 'Peso (kg)', _validatorOpcionalPositivo)),
                      const SizedBox(width: 8),
                      Expanded(child: _campoNumero(_pesoMaxController, 'Peso máx. (kg)', _validatorOpcionalPositivo)),
                      if (_tipoDeCarga != TipoCarga.bultos) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _volumenController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Volumen (m³)', border: OutlineInputBorder()),
                            validator: _validatorOpcionalPositivo,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_tipoDeCarga == TipoCarga.bultos) bultosForm(),
                  const SizedBox(height: 8),
                  _campoNumero(_precioController, 'Precio del transporte (€)', _validatorOpcionalPositivo),
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

  Widget bultosForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _campoNumero(_numBultosController, 'Nº bultos', (v) => _validatorOpcionalPositivo(v, entero: true))),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_largoController, 'Largo (m)', _validatorOpcionalPositivo)),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_anchoController, 'Ancho (m)', _validatorOpcionalPositivo)),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_altoController, 'Alto (m)', _validatorOpcionalPositivo)),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _apilable,
          onChanged: (v) => setState(() => _apilable = v ?? false),
          title: const Text('Apilable'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}