import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.value,
    required this.label,
  });

  final String? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(value ?? '-', style: AppTextStyles.kpiValue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.kpiLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ViajeCard extends StatelessWidget {
  final String fechaHora;
  final String origenDestino;

  const ViajeCard({super.key, required this.fechaHora, required this.origenDestino});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Próximo: '),
          Text(fechaHora, style: AppTextStyles.kpiLabel),
          const SizedBox(height: 4),
          Text(
            origenDestino,
            style: AppTextStyles.kpiValue.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

