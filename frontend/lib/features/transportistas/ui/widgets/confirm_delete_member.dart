import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../transportista_provider.dart';

class ConfirmDeleteMember extends StatelessWidget {
  final String uid;
  final String nombreCompleto;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDeleteMember({
    super.key,
    required this.uid,
    required this.nombreCompleto,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar miembro del equipo'),
      content: Text('¿Estás seguro de que quieres dar de baja a $nombreCompleto? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: context.watch<TransportistaProvider>().isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
