import 'package:flutter/cupertino.dart';

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
    return CupertinoAlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text(_buildContent(conductor)),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm,
          isDestructiveAction: true,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}