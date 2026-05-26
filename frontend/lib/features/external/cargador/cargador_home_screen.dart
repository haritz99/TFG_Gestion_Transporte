import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/dashboard/ui/widgets/nuevo_pedido/form_builder.dart';
import 'package:gestion_transporte/core/theme/app_colors.dart';
import 'package:gestion_transporte/core/widgets/external_home.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/cargas/providers/pedido_provider.dart';

class CargadorHomeScreen extends StatefulWidget {
  const CargadorHomeScreen({super.key});

  @override
  State<CargadorHomeScreen> createState() => _CargadorHomeScreenState();
}

class _CargadorHomeScreenState extends State<CargadorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchPedidos();
    });
  }

  Future<void> _prefetchPedidos() async {
    final provider = context.read<PedidoProvider>();
    if (provider.pedidos.isEmpty) {
      await provider.getPedidosDelCargador();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoProvider>();
    return ExternalHome(
      title: 'Panel de Cargador',
      subtitle: 'Realiza y gestiona tus pedidos.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _mostrarNuevoPedido(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Pedido'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => context.push('/cargador_pedidos'),
          icon: const Icon(Icons.list_alt, color: AppColors.primary),
          label: const Text('Gestiona tus pedidos', style: TextStyle(color: AppColors.primary)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarNuevoPedido(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FormBuilderPedido(),
    );
  }
}

