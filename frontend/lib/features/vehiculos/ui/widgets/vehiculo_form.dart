import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/vehiculo_model.dart';

class VehiculoForm extends StatefulWidget {
  const VehiculoForm({
    super.key,
    this.vehiculo,
    this.conductores = const [],
    required this.onSave,
  });

  final VehiculoModel? vehiculo;
  final List<DropdownMenuEntry<String>> conductores;
  final ValueChanged<VehiculoModel> onSave;

  @override
  State<VehiculoForm> createState() => _VehiculoFormState();
}

class _VehiculoFormState extends State<VehiculoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _matriculaController;
  late final TextEditingController _marcaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _capacidadController;
  late final TextEditingController _largoController;
  late final TextEditingController _anchoController;
  late final TextEditingController _altoController;
  late final TextEditingController _matriculaRemolqueController;


  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;

    _matriculaController = TextEditingController(text: v?.matricula ?? '');
    _marcaController = TextEditingController(text: v?.marca ?? '');
    _modeloController = TextEditingController(text: v?.modelo ?? '');
    _capacidadController = TextEditingController(text: (v?.capacidad ?? '').toString());
    _largoController = TextEditingController(text: (v?.largo ?? '').toString());
    _anchoController = TextEditingController(text: (v?.ancho ?? '').toString());
    _altoController = TextEditingController(text: (v?.alto ?? '').toString());
    _matriculaRemolqueController = TextEditingController(text: v?.matriculaRemolque ?? '');

  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _capacidadController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _matriculaRemolqueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {

      final nuevoVehiculo = VehiculoModel(
        matricula: _matriculaController.text.trim().toUpperCase(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        capacidad: double.tryParse(_capacidadController.text) ?? 0.0,
        largo: double.tryParse(_largoController.text) ?? 0.0,
        ancho: double.tryParse(_anchoController.text) ?? 0.0,
        alto: double.tryParse(_altoController.text) ?? 0.0,
        matriculaRemolque: _matriculaRemolqueController.text.trim().toUpperCase(),
        companyId: widget.vehiculo?.companyId,
      );

      widget.onSave(nuevoVehiculo);
    }
  }

  String? _validatePositiveDouble(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final val = double.tryParse(v.trim());
    if (val == null || val <= 0) return '> 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _matriculaController,
                  decoration: const InputDecoration(labelText: 'Matrícula', border: OutlineInputBorder()),
                  enabled: widget.vehiculo == null, // Solo editable si es nuevo
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!RegExp(r'^[0-9]{4}[a-zA-Z]{3}$').hasMatch(v.trim())) return 'Formato: 1234ABC';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _marcaController, decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _capacidadController, decoration: const InputDecoration(labelText: 'Capacidad (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: _validatePositiveDouble)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _largoController, decoration: const InputDecoration(labelText: 'Largo (m)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: _validatePositiveDouble)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _anchoController, decoration: const InputDecoration(labelText: 'Ancho (m)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: _validatePositiveDouble)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _altoController, decoration: const InputDecoration(labelText: 'Alto (m)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: _validatePositiveDouble)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFormField(
                controller: _matriculaRemolqueController,
                decoration: const InputDecoration(labelText: 'Matrícula Remolque (opcional)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && !RegExp(r'^[0-9]{4}[a-zA-Z]{3}$').hasMatch(v.trim())) return 'Formato: 1234ABC';
                  return null;
                },
              )),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(widget.vehiculo == null ? 'Crear Vehículo' : 'Actualizar Vehículo', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

}