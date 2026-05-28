import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/theme/app_colors.dart';
import 'package:gestion_transporte/core/widgets/external_home.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/cargas/providers/carga_provider.dart';

class SubHomeScreen extends StatefulWidget {
  const SubHomeScreen({super.key});

  @override
  State<SubHomeScreen> createState() => _SubHomeScreenState();
}

class _SubHomeScreenState extends State<SubHomeScreen> {
  @override
  void initState() {
    super.initState();
    _prefetchCargas();
  }

  Future<void> _prefetchCargas() async {
    final provider = context.read<CargaProvider>();
    if (provider.cargasCedidas.isEmpty) {
      await provider.fetchCargasCedidas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CargaProvider>();
    return ExternalHome(
      title: 'Panel de Subcontratado',
      subtitle: 'Gestiona tus viajes y cartas de porte.',
      actions: [
        ElevatedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => context.push('/sub_pedidos'),
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
            context.push('/sub_cartas_porte');
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
