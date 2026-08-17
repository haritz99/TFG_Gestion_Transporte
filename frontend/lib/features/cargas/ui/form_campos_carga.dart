import 'package:flutter/material.dart';
import '../../../core/models/carga_model.dart';
import '../../../core/models/direccion_model.dart';
import '../../../core/services/ubicacion_search_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DatosCamposCarga {
  final String mercancia;
  final TipoCarga tipoCarga;
  final String? tipoEmbalaje;
  final int? numBultos;
  final double? peso;
  final double? volumen;
  final double? largo;
  final double? ancho;
  final double? alto;
  final bool apilable;
  final double precio;
  final UbicacionModel origen;
  final UbicacionModel destino;

  const DatosCamposCarga({
    required this.mercancia,
    required this.tipoCarga,
    required this.tipoEmbalaje,
    required this.numBultos,
    required this.peso,
    required this.volumen,
    required this.largo,
    required this.ancho,
    required this.alto,
    required this.apilable,
    required this.precio,
    required this.origen,
    required this.destino,
  });
}

class FormCamposCarga extends StatefulWidget {
  final CargaBaseModel? valorInicial;
  final bool esEdicion;

  const FormCamposCarga({super.key, this.valorInicial, this.esEdicion = false});

  @override
  State<FormCamposCarga> createState() => FormCamposCargaState();
}

class FormCamposCargaState extends State<FormCamposCarga> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _mercanciaController;
  late final TextEditingController _tipoEmbalajeController;
  late final TextEditingController _numBultosController;
  late final TextEditingController _pesoController;
  late final TextEditingController _volumenController;
  late final TextEditingController _precioController;
  late final TextEditingController _largoController;
  late final TextEditingController _anchoController;
  late final TextEditingController _altoController;
  late final UbicacionControllers _origenUbicacion;
  late final UbicacionControllers _destinoUbicacion;

  late TipoCarga _tipoDeCarga;
  late bool _apilable;

  @override
  void initState() {
    super.initState();
    final inicial = widget.valorInicial;
    _tipoDeCarga = inicial?.tipoCarga ?? TipoCarga.bultos;
    _apilable = inicial?.apilable ?? false;
    _mercanciaController = TextEditingController(text: inicial?.mercancia ?? '');
    _tipoEmbalajeController = TextEditingController(text: inicial?.tipoEmbalaje ?? '');
    _numBultosController = TextEditingController(text: inicial?.numBultos?.toString() ?? '');
    _pesoController = TextEditingController(text: inicial?.peso?.toString() ?? '');
    _volumenController = TextEditingController(text: inicial?.volumen?.toString() ?? '');
    _precioController = TextEditingController(text: inicial?.precio.toString() ?? '');
    _largoController = TextEditingController(text: inicial?.largo?.toString() ?? '');
    _anchoController = TextEditingController(text: inicial?.ancho?.toString() ?? '');
    _altoController = TextEditingController(text: inicial?.alto?.toString() ?? '');
    _origenUbicacion = UbicacionControllers();
    _destinoUbicacion = UbicacionControllers();
    if (inicial != null) {
      _origenUbicacion.cargarUbicacion(inicial.origen);
      _destinoUbicacion.cargarUbicacion(inicial.destino);
    }
  }

  @override
  void dispose() {
    _mercanciaController.dispose();
    _tipoEmbalajeController.dispose();
    _numBultosController.dispose();
    _pesoController.dispose();
    _volumenController.dispose();
    _precioController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _origenUbicacion.dispose();
    _destinoUbicacion.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  DatosCamposCarga get datos => DatosCamposCarga(
        mercancia: _mercanciaController.text.trim(),
        tipoCarga: _tipoDeCarga,
        tipoEmbalaje: _tipoEmbalajeController.text.trim().isEmpty ? null : _tipoEmbalajeController.text.trim(),
        numBultos: int.tryParse(_numBultosController.text.trim()),
        peso: _toDouble(_pesoController.text),
        volumen: _toDouble(_volumenController.text),
        largo: _toDouble(_largoController.text),
        ancho: _toDouble(_anchoController.text),
        alto: _toDouble(_altoController.text),
        apilable: _apilable,
        precio: _toDouble(_precioController.text) ?? 0,
        origen: _origenUbicacion.toModel(),
        destino: _destinoUbicacion.toModel(),
  );

  static String? validatorRequerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    return null;
  }

  static String? validatorOpcionalPositivo(String? value, {bool entero = false}) {
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
    final esEdicion = widget.esEdicion;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _mercanciaController,
            enabled: !esEdicion,
            decoration: const InputDecoration(labelText: 'Mercancía', border: OutlineInputBorder()),
            validator: validatorRequerido,
          ),
          const SizedBox(height: 8),
          if (esEdicion)
            _campoLectura('Tipo de carga', _tipoDeCarga.label)
          else
            DropdownButtonFormField<String>(
              initialValue: _tipoDeCarga.value,
              items: const [
                DropdownMenuItem(value: 'bultos', child: Text('Bultos')),
                DropdownMenuItem(value: 'granel', child: Text('Granel')),
                DropdownMenuItem(value: 'liquido', child: Text('Líquido')),
              ],
              decoration: const InputDecoration(labelText: 'Tipo de carga', border: OutlineInputBorder()),
              validator: validatorRequerido,
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
              Expanded(child: _campoNumero(_pesoController, 'Peso (kg)', validatorOpcionalPositivo)),
              if (_tipoDeCarga != TipoCarga.bultos) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _volumenController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Volumen (m³)', border: OutlineInputBorder()),
                    validator: validatorOpcionalPositivo,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_tipoDeCarga == TipoCarga.bultos) bultosForm(),
          const SizedBox(height: 8),
          _campoNumero(_precioController, 'Precio del transporte (€)', validatorOpcionalPositivo),
        ],
      ),
    );
  }

  Widget _campoLectura(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: Text(value),
    );
  }

  Widget bultosForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _campoNumero(_numBultosController, 'Nº bultos', (v) => validatorOpcionalPositivo(v, entero: true))),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_largoController, 'Largo (m)', validatorOpcionalPositivo)),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_anchoController, 'Ancho (m)', validatorOpcionalPositivo)),
            const SizedBox(width: 8),
            Expanded(child: _campoNumero(_altoController, 'Alto (m)', validatorOpcionalPositivo)),
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