import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlanHeader extends StatelessWidget {
  const PlanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13.5),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Planificación de Cargas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyText,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implementar guardado de cambios o sincronización manual
            },
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Guardar cambios'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: const BorderSide(color: AppColors.border),
            ),
          )
        ],
      ),
    );
  }
}
