import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/theme/app_colors.dart';
import 'package:gestion_transporte/core/widgets/external_home.dart';

class SubHomeScreen extends StatelessWidget {
  const SubHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ExternalHome(
      title: 'Panel de Subcontratado',
      subtitle: 'Gestiona tus viajes y cartas de porte.',
      actions: [
        ElevatedButton.icon(
          onPressed: () {

          },
          icon: const Icon(Icons.airport_shuttle),
          label: const Text('Gestiona las cargas cedidas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate or show dialog
          },
          icon: const Icon(Icons.list),
          label: const Text('Revisa tus cartas de porte'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

