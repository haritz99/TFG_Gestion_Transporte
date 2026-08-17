import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/cargas/providers/carga_provider.dart';
import 'package:gestion_transporte/features/cargas/providers/pedido_provider.dart';
import 'package:gestion_transporte/features/transportistas/transportista_provider.dart';
import 'package:gestion_transporte/features/vehiculos/vehiculo_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/pedido_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:gestion_transporte/features/dashboard/providers/invite_provider.dart';
import 'package:gestion_transporte/features/dashboard/providers/dashboard_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/ui/shared_register.dart';
import 'datos_cliente.dart';
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

  final GlobalKey<DatosClienteFormState> _datosClienteFormKey = GlobalKey<DatosClienteFormState>();
  final _nombreController = TextEditingController();
  final _nifController = TextEditingController();
  final _direccionControllers = SharedRegisterControllers();

  final GlobalKey<NuevoPedidoFormState> _pedidoFormKey = GlobalKey<NuevoPedidoFormState>();
  final GlobalKey<SeleccionarCargasFormState> _cargasFormKey = GlobalKey<SeleccionarCargasFormState>();

  @override
  void initState() {
    super.initState();
    final pedidoProvider = context.read<PedidoProvider>();
    _nombreController.text = pedidoProvider.datosTemporalPedido['clienteNombre'] ?? '';
    _nifController.text = pedidoProvider.datosTemporalPedido['clienteNif'] ?? '';
    _direccionControllers.calle.text = pedidoProvider.datosTemporalPedido['clienteCalle'] ?? '';
    _direccionControllers.codigoPostal.text = pedidoProvider.datosTemporalPedido['clienteCp'] ?? '';
    _direccionControllers.ciudad.text = pedidoProvider.datosTemporalPedido['clienteCiudad'] ?? '';
    _direccionControllers.provincia.text = pedidoProvider.datosTemporalPedido['clienteProvincia'] ?? '';

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
    _nombreController.dispose();
    _nifController.dispose();
    _direccionControllers.dispose();
    super.dispose();
  }

  void _onSiguiente() async {
    final pedidoProvider = context.read<PedidoProvider>();

    if (_currentPage == 0) {
      if (_datosClienteFormKey.currentState?.validate() ?? false) {
        pedidoProvider.actualizarDatosTemporales(
          clienteNombre: _nombreController.text.trim(),
          clienteNif: _nifController.text.trim(),
          clienteCalle: _direccionControllers.calle.text.trim(),
          clienteCp: _direccionControllers.codigoPostal.text.trim(),
          clienteCiudad: _direccionControllers.ciudad.text.trim(),
          clienteProvincia: _direccionControllers.provincia.text.trim(),
        );

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 1);
      }
    } else if (_currentPage == 1) {
      if (_pedidoFormKey.currentState?.validate() ?? false) {
        final formState = _pedidoFormKey.currentState;
        final cliente = formState?.selectedCliente;
        if (cliente != null) {
          final cargaProvider = context.read<CargaProvider>();
          final transportistaProvider = context.read<TransportistaProvider>();
          final vehiculoProvider = context.read<VehiculoProvider>();
          await Future.wait([
            cargaProvider.fetchTiposCarga(cliente.uid),
            transportistaProvider.loadInitialEquipo(limit: 1000),
            vehiculoProvider.loadInitialVehiculos(),
            //cargaProvider.loadCargas()
          ]);
        }
        if (!mounted) return;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 2);
      }
    } else {
      final pedidoProvider = context.read<PedidoProvider>();

      final ok = await pedidoProvider.crearPedido();
      if (!mounted) return;
        if (ok) {
        Future.wait([
        context.read<DashboardProvider>().refresh(),
        context.read<CargaProvider>().fetchCargasIniciales(forceRefresh: true),
        ]);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(pedidoProvider.errorMessage ?? 'Error al crear el pedido'),
            backgroundColor: Colors.red,
          ),
        );
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
                      child: DatosClienteForm(
                        key: _datosClienteFormKey,
                        nombreController: _nombreController,
                        nifController: _nifController,
                        direccionControllers: _direccionControllers,
                      ),
                    ),
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
    final canNext = pedidoProvider.cargasDelPedido != null || _currentPage == 0;

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
          child: Text(_currentPage != 2 ? 'Siguiente' : 'Finalizar',
              style: AppTextStyles.buttonSmall),
        ),
      ],
    );
  }
}
