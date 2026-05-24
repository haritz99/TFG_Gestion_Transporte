import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cargas/providers/carga_provider.dart';

class PlanHeader extends StatelessWidget {
  const PlanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
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
          Consumer<CargaProvider>(
            builder: (context, provider, child) {
              return OutlinedButton.icon(
                onPressed: provider.hayCambiosSinGuardar && !provider.isLoading
                    ? () async {
                        await provider.guardarCambios();
                        if (context.mounted) {
                          if (provider.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: ${provider.errorMessage}',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cambios guardados correctamente',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: const Text('Guardar cambios'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: provider.hayCambiosSinGuardar
                      ? AppColors.primary
                      : AppColors.mutedText,
                  side: BorderSide(
                    color: provider.hayCambiosSinGuardar
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
