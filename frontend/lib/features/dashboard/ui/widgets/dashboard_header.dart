import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/token_provider.dart';
import '../../providers/invite_provider.dart';
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
              ElevatedButton.icon(
                onPressed: () {
                  final tokenProvider = context.read<AuthTokenProvider>();
                  showDialog(
                    context: context,
                    builder: (ctx) => ChangeNotifierProvider<InviteProvider>(
                      create: (_) => InviteProvider(
                        tokenProvider: tokenProvider,
                      ),
                      child: const FormBuilderPedido(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Pedido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final tokenProvider = context.read<AuthTokenProvider>();
                  showDialog(
                    context: context,
                    builder: (ctx) => ChangeNotifierProvider<InviteProvider>(
                      create: (_) => InviteProvider(
                        tokenProvider: tokenProvider,
                      ),
                      child: const InviteModal(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.person_add,
                  size: 18,
                ),
                label: const Text('Invitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
