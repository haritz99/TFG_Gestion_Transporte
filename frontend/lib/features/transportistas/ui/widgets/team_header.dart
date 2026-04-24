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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Gestión de Equipo',
          style: AppTextStyles.headingLg
        ),
        SizedBox(height: 4),
        Text(
          'Conductores y encargados registrados',
          style: AppTextStyles.bodyMd,
        ),
      ],
    );

    final button = SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onAddMiembro,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Añadir Miembro',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        button,
      ],
    );
  }
}
