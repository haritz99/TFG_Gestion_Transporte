import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/nuevo_pedido/form_builder.dart';
import 'package:gestion_transporte/core/theme/app_colors.dart';
import 'package:gestion_transporte/core/widgets/external_home.dart';

class CargadorHomeScreen extends StatelessWidget {
  const CargadorHomeScreen({super.key});



  @override
  Widget build(BuildContext context) {
    return ExternalHome(
      title: 'Panel de Cargador',
      subtitle: 'Registra un nuevo pedido de transporte ahora.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _mostrarNuevoPedido(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Pedido'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _mostrarNuevoPedido(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FormBuilderPedido(),
    );
  }
}
