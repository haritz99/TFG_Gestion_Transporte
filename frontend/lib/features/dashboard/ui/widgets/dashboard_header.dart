import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'invite/invite_modal.dart';
import 'nuevo_pedido/form_builder.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now());

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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel de control',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                today,
                style: AppTextStyles.bodyMd,
              ),
            ],
          ),
          Row(
            children: [
              _responsiveButton(
                label: 'Nuevo Pedido',
                icon: Icons.add,
                backgroundColor: AppColors.primary,
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const FormBuilderPedido(),
                ),
              ),
              const SizedBox(width: 12),
              _responsiveButton(
                label: 'Invitar',
                icon: Icons.person_add,
                backgroundColor: const Color(0xFF4CAF50),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const InviteModal(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responsiveButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Builder(builder: (ctx) {
      final isMobile = ResponsiveBreakpoints.of(ctx).isMobile;

      final style = ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: isMobile
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

      if (isMobile) {
        return Tooltip(
          message: label,
          child: ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: Icon(icon, size: 20),
          ),
        );
      }

      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: style,
      );
    });
  }
}
