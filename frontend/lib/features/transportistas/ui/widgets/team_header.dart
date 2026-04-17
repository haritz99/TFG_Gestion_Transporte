import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TeamHeader extends StatelessWidget {
  final VoidCallback? onAddMiembro;
  final bool isMobile;

  const TeamHeader({
    super.key,
    this.onAddMiembro,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Equipo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.bodyText,
              ),
            ),
            Text(
              'Conductores y encargados registrados',
              style: AppTextStyles.bodyMd,
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAddMiembro,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Añadir Miembro'),
        ),
      ],
    );
  }
}

