import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/vehiculos/ui/widgets/vehiculo_form.dart';
import 'package:provider/provider.dart';

import '../../../core/models/vehiculo_model.dart';
import '../../auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../transportistas/providers/transportista_provider.dart';
import '../providers/vehiculo_provider.dart';
import 'gestion_flota_page.dart';
import 'models/fleet_table_row_model.dart';
import 'widgets/confirm_delete_vehicle.dart';

class GestionFlotaScreen extends StatelessWidget {
  const GestionFlotaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoProvider(authService: AuthService())),
        ChangeNotifierProvider(create: (_) => TransportistaProvider(authService: AuthService())),
      ],
      child: const _GestionFlotaScreenBody(),
    );
  }
}

class _GestionFlotaScreenBody extends StatefulWidget {
  const _GestionFlotaScreenBody();

  @override
  State<_GestionFlotaScreenBody> createState() => _GestionFlotaScreenBodyState();
}

class _GestionFlotaScreenBodyState extends State<_GestionFlotaScreenBody> {
  static const int _pageSize = AppConstants.vehiclePaginationPageSize;

  final List<VehiculoModel> _vehiculos = [];
  bool _firstLoad = true;
  bool _isLoadingPage = false;
  bool _hasMore = true;
  String? _lastDocId;
  String _selectedStatus = 'Todos';

  List<VehiculoModel> get _vehiculosFiltrados {
    switch (_selectedStatus) {
      case 'Asignado':
        return _vehiculos.where((v) => v.estado == 'asignado').toList();
      case 'Disponible':
        return _vehiculos.where((v) => v.estado == 'disponible').toList();
      case 'Mantenimiento':
        return _vehiculos.where((v) => v.estado == 'mantenimiento').toList();
      default:
        return _vehiculos;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<VehiculoProvider>();
    await provider.fetchKpis();
    await _loadNextPage(reset: true);
    if (!mounted) return;
    setState(() {
      _firstLoad = false;
    });
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_isLoadingPage) return;
    if (!reset && !_hasMore) return;

    setState(() {
      _isLoadingPage = true;
    });

    final provider = context.read<VehiculoProvider>();
    final response = await provider.fetchVehiculosPage(
      limit: _pageSize,
      lastDocId: reset ? null : _lastDocId,
    );

    if (!mounted) return;

    setState(() {
      if (reset) {
        _vehiculos
          ..clear()
          ..addAll(response.items);
      } else {
        _vehiculos.addAll(response.items);
      }
      _lastDocId = response.lastDocId;
      _hasMore = response.hasMore;
      _isLoadingPage = false;
    });
  }

  String _formatEstado(String rawStatus) {
    if (rawStatus.isEmpty) return 'Desconocido';
    return rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
  }

  void _promptDeleteVehiculo(String matricula) {
    final vehiculo = _vehiculos.firstWhere((v) => v.matricula == matricula);
    final conductor = vehiculo.transportistaNombre ?? '';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteVehicle(
        conductor: conductor,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () {
          Navigator.of(ctx).pop();
          deleteVehiculo(matricula);
        },
      ),
    );
  }

  Future<void> _promptVehiculoForm(String? matricula) async {
    final vehiculoProvider = context.read<VehiculoProvider>();
    final transportistaProvider = context.read<TransportistaProvider>();
    final isNew = matricula == null;

    final vehiculoActual = isNew ? null : _vehiculos.firstWhere((v) => v.matricula == matricula);

    await transportistaProvider.fetchTransportistasDisponibles();
    final conductores = transportistaProvider.getConductoresDropdown();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isNew ? 'Crear vehículo' : 'Editar vehículo'),
          content: SizedBox(
            width: 900,
            child: SingleChildScrollView(
              child: VehiculoForm(
                vehiculo: vehiculoActual,
                conductores: conductores,
                onSave: (vehiculo) async {
                  final saved = await vehiculoProvider.saveVehiculo(vehiculo, isNew: isNew);
                  if (!mounted || saved == null) return;
                  if (!ctx.mounted) return;

                  Navigator.of(ctx).pop();

                  if (isNew) {
                    await _loadInitialData();
                    return;
                  }

                  final index = _vehiculos.indexWhere((item) => item.matricula == saved.matricula);
                  if (index != -1) {
                    setState(() {
                      _vehiculos[index] = saved;
                    });
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteVehiculo(String matricula) async {
    final provider = context.read<VehiculoProvider>();
    await provider.eliminarVehiculo(matricula);
    if (!mounted) return;

    final error = provider.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehículo eliminado correctamente')),
    );

    setState(() {
      _vehiculos.removeWhere((item) => item.matricula == matricula);
    });
  }

  Future<void> _handleDesktopPageChanged(int firstRowIndex) async {
    final filteredCount = _vehiculosFiltrados.length;
    if (firstRowIndex + _pageSize > filteredCount && _hasMore) {
      await _loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculoProvider>();

    if (_firstLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rows = _vehiculosFiltrados.map((v) {
      return FleetTableRowModel(
        matricula: v.matricula,
        marca: v.marca,
        modelo: v.modelo,
        capacidad: '${v.capacidad}t',
        largo: '${v.largo}m',
        ancho: '${v.ancho}m',
        alto: '${v.alto}m',
        estado: _formatEstado(v.estado),
        interno: v.interno ? 'Interno' : 'Subcontratado',
        matriculaRemolque: v.matriculaRemolque ?? '',
        conductor: v.transportistaNombre ?? 'Sin asignar',
      );
    }).toList();

    return Scaffold(
      body: GestionFlotaPage(
        totalVehiculos: provider.totalVehiculos ?? 0,
        asignados: provider.asignados ?? 0,
        enMantenimiento: provider.enMantenimiento ?? 0,
        disponibles: provider.disponibles ?? 0,
        selectedStatus: _selectedStatus,
        statusOptions: const ['Todos', 'Asignado', 'Disponible', 'Mantenimiento'],
        rows: rows,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingPage,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onAddVehiculo: () => _promptVehiculoForm(null),
        onDeleteVehiculo: _promptDeleteVehiculo,
        onEditVehiculo: _promptVehiculoForm,
        onMobileLoadMore: _loadNextPage,
        onDesktopPageChanged: _handleDesktopPageChanged,
      ),
    );
  }
}
