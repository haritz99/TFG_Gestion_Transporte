import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transportista_provider.dart';

class ConfirmDeleteMember extends StatelessWidget {
  final String uid;
  final String nombreCompleto;

  const ConfirmDeleteMember({
    super.key,
    required this.uid,
    required this.nombreCompleto,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar miembro del equipo'),
      content: Text('¿Estás seguro de que quieres eliminar a $nombreCompleto? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final provider = context.read<TransportistaProvider>();
            final success = await provider.deleteTransportista(uid);
            if (context.mounted) {
              if (success) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage ?? 'Error al eliminar')),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: context.watch<TransportistaProvider>().isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

