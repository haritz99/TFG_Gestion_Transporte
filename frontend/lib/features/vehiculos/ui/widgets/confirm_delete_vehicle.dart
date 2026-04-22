import 'package:flutter/material.dart';

class ConfirmDeleteVehicle extends StatelessWidget{
  const ConfirmDeleteVehicle({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.conductor = '',
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String conductor;

  String _buildContent(String conductor) {
    if (conductor.isNotEmpty && conductor != 'Sin asignar') {
      return "¿Estás seguro de que deseas eliminar este vehículo?\n\nEste vehículo tiene asignado a ($conductor), también se eliminará la asignación.";
    } else {
      return "¿Estás seguro de que deseas eliminar este vehículo?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text(_buildContent(conductor)),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}