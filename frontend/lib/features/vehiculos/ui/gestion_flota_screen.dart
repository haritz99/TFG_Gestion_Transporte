import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/vehiculos/ui/widgets/vehiculo_form.dart';
import 'package:provider/provider.dart';

import '../../../core/models/vehiculo_model.dart';
import '../../../core/app_constants.dart';
import '../../cargas/providers/carga_provider.dart';
import '../vehiculo_provider.dart';
import 'gestion_flota_page.dart';
import 'models/fleet_table_row_model.dart';
import 'widgets/confirm_delete_vehicle.dart';

class GestionFlotaScreen extends StatelessWidget {
  const GestionFlotaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GestionFlotaScreenBody();
  }
}

class _GestionFlotaScreenBody extends StatefulWidget {
  const _GestionFlotaScreenBody();

  @override
  State<_GestionFlotaScreenBody> createState() => _GestionFlotaScreenBodyState();
}

class _GestionFlotaScreenBodyState extends State<_GestionFlotaScreenBody> {
  static const int _pageSize = AppConstants.paginationPageSize;

  VehiculoProvider get _vehiculoProvider => context.read<VehiculoProvider>();

  bool _firstLoad = true;
  String _selectedStatus = 'Todos';

  List<VehiculoModel> _filterVehiculos(List<VehiculoModel> source, CargaProvider cargaProvider) {
    if (_selectedStatus == 'Todos') return source;
    return source.where((v) {
      final estado = cargaProvider.estadoVehiculo(v.matricula);
      switch (_selectedStatus) {
        case 'Asignado':      return estado == 'asignado';
        case 'Disponible':    return estado == 'disponible';
        default: return true;
      }
    }).toList();
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
    await _vehiculoProvider.loadInitialVehiculos(limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _firstLoad = false;
    });
  }

  String _formatEstado(String rawStatus) {
    if (rawStatus.isEmpty) return 'Desconocido';
    return rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
  }

  void _promptDeleteVehiculo(String matricula) {
    final conductor = context.read<CargaProvider>().conductorDeVehiculo(matricula) ?? 'Sin asignar';

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
    final isNew = matricula == null;

    final vehiculoActual = isNew ? null : vehiculoProvider.vehiculos.firstWhere((v) => v.matricula == matricula);

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
                onSave: (vehiculo) async {
                  final saved = await vehiculoProvider.saveVehiculo(vehiculo, isNew: isNew);
                  if (!mounted || saved == null) return;
                  if (!ctx.mounted) return;

                  Navigator.of(ctx).pop();
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
  }

  Future<void> _handleDesktopPageChanged(int firstRowIndex) async {
    final filteredCount = _vehiculoProvider.vehiculos.length;
    if (firstRowIndex + _pageSize > filteredCount && _vehiculoProvider.hasMore) {
      await _vehiculoProvider.loadNextPage(limit: _pageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculoProvider>();

    if (_firstLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cargaProvider = context.watch<CargaProvider>();
    final filtered = _filterVehiculos(provider.vehiculos, cargaProvider);

    final rows = filtered.map((v) {
      return FleetTableRowModel(
        matricula: v.matricula,
        marca: v.marca,
        modelo: v.modelo,
        capacidad: '${v.capacidad}t',
        largo: '${v.largo}m',
        ancho: '${v.ancho}m',
        alto: '${v.alto}m',
        estado: _formatEstado(cargaProvider.estadoVehiculo(v.matricula)),
        matriculaRemolque: v.matriculaRemolque ?? '',
        conductor: cargaProvider.conductorDeVehiculo(v.matricula) ?? 'Sin asignar',
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
        hasMore: provider.hasMore,
        isLoadingMore: provider.isLoadingPage,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onAddVehiculo: () => _promptVehiculoForm(null),
        onDeleteVehiculo: _promptDeleteVehiculo,
        onEditVehiculo: _promptVehiculoForm,
        onMobileLoadMore: () => provider.loadNextPage(limit: _pageSize),
        onDesktopPageChanged: _handleDesktopPageChanged,
      ),
    );
  }
}
