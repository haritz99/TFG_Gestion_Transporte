import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class GestionFlotaHeader extends StatelessWidget {
  const GestionFlotaHeader({
    super.key,
    required this.onAddVehiculo,
    required this.isMobile,
  });

  final VoidCallback? onAddVehiculo;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Gestion de Flota', style: AppTextStyles.headingLg),
        SizedBox(height: 4),
        Text(
          'Control y seguimiento de todos los vehiculos',
          style: AppTextStyles.bodyMd,
        ),
      ],
    );

    final button = SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onAddVehiculo,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Anadir Vehiculo',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
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
      children: [content, button],
    );
  }
}

