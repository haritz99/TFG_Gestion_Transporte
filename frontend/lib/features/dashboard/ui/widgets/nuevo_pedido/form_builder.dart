import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/cargas/providers/carga_provider.dart';
import 'package:gestion_transporte/features/cargas/providers/pedido_provider.dart';
import 'package:gestion_transporte/features/transportistas/providers/transportista_provider.dart';
import 'package:gestion_transporte/features/vehiculos/providers/vehiculo_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/external_user_model.dart';
import '../../../../../core/models/pedido_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'package:gestion_transporte/features/dashboard/providers/invite_provider.dart';
import 'package:gestion_transporte/features/dashboard/providers/dashboard_provider.dart';
import '../../../../auth/providers/auth_provider.dart';
import 'nuevo_pedido.dart';
import 'seleccionar_cargas.dart';

class FormBuilderPedido extends StatefulWidget {
  final PedidoModel? pedidoParaEditar;

  const FormBuilderPedido({super.key, this.pedidoParaEditar});
  @override
  State<FormBuilderPedido> createState() => _FormBuilderPedidoState();
}
class _FormBuilderPedidoState extends State<FormBuilderPedido> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  ExternalUserModel? _clienteSeleccionado;
  String _descripcion = '';
  DateTime? _fechaCarga;
  DateTime? _fechaDescarga;
  final GlobalKey<NuevoPedidoFormState> _pedidoFormKey = GlobalKey<NuevoPedidoFormState>();
  final GlobalKey<SeleccionarCargasFormState> _cargasFormKey = GlobalKey<SeleccionarCargasFormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<InviteProvider>().getGuests();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSiguiente() async {
    if (_currentPage == 0) {
      if (_pedidoFormKey.currentState?.validate() ?? false) {
        final formState = _pedidoFormKey.currentState;
        final cliente = formState?.selectedCliente;
        if (cliente != null && formState != null) {
          _clienteSeleccionado = cliente;
          _descripcion = formState.descripcion;
          _fechaCarga = formState.fechaCarga;
          _fechaDescarga = formState.fechaDescarga;
          final cargaProvider = context.read<CargaProvider>();
          final transportistaProvider = context.read<TransportistaProvider>();
          final vehiculoProvider = context.read<VehiculoProvider>();
          await Future.wait([
            cargaProvider.fetchTiposCarga(cliente.uid),
            transportistaProvider.fetchTransportistasDisponibles(),
            vehiculoProvider.loadInitialVehiculos(),
          ]);
        }
        if (!mounted) return;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 1);
      }
    } else {
      final pedidoProvider = context.read<PedidoProvider>();

      if (_clienteSeleccionado != null && _fechaCarga != null && _fechaDescarga != null) {
        final ok = await pedidoProvider.crearPedido(
          descripcion: _descripcion,
          clienteId: _clienteSeleccionado!.uid,
          fechaCarga: _fechaCarga!,
          fechaDescarga: _fechaDescarga!,
        );
        if (!mounted) return;
        if (ok) {
          context.read<DashboardProvider>().refresh();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pedidoProvider.errorMessage ?? 'Error al crear el pedido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onAtras() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<InviteProvider>();
    final clientes = clientesProvider.guests
        .where((g) => g.rol.contains('cliente') && g.datosCompletos == true)
        .toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 32, color: AppColors.border),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SingleChildScrollView(
                      child: NuevoPedidoForm(
                        key: _pedidoFormKey,
                        clientes: clientes,
                      ),
                    ),
                    SingleChildScrollView(
                      child: SeleccionarCargasForm(
                        key: _cargasFormKey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Pedido', style: AppTextStyles.headingLg),
            const SizedBox(height: 4),
            Text(
              _currentPage == 0 ? 'Registrar nuevo envío' : 'Seleccionar cargas',
              style: AppTextStyles.bodyMd,
            ),
          ],
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('X', style: AppTextStyles.headingMd),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();
    final canNext = pedidoProvider.cargasDelPedido != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentPage == 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText)),
          )
        else
          TextButton(
            onPressed: _onAtras,
            child: Text('Atrás',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText)),
          ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: canNext ? _onSiguiente : null,
          child: Text(_currentPage == 0 ? 'Siguiente' : 'Finalizar',
              style: AppTextStyles.buttonSmall),
        ),
      ],
    );
  }
}
