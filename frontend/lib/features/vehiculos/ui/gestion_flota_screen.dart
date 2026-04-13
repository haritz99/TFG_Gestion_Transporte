import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/vehiculo_model.dart';
import '../providers/vehiculo_provider.dart';
import 'models/fleet_table_row_model.dart';
import 'gestion_flota_page.dart';
import '../../auth/auth_service.dart';
import 'widgets/confirm_delete_vehicle.dart';
import 'package:flutter/cupertino.dart';

class GestionFlotaScreen extends StatelessWidget {
  const GestionFlotaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VehiculoProvider(authService: AuthService()),
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
  List<VehiculoModel> _vehiculos = [];
  bool _firstLoad = true;
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
      _refreshVehiculos();
    });
  }

  Future<void> _refreshVehiculos() async {
    final provider = context.read<VehiculoProvider>();
    final list = await provider.fetchVehiculos();
    if (mounted) {
      setState(() {
        _vehiculos = list;
        _firstLoad = false;
      });
    }
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

  Future<void> deleteVehiculo(String matricula) async {
    final provider = context.read<VehiculoProvider>();
    await provider.eliminarVehiculo(matricula);
    if (mounted) {
      final error = provider.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo eliminado correctamente')),
        );
        _refreshVehiculos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<VehiculoProvider>();

    if (_firstLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Mapear los modelos de dominio a los modelos de la UI de presentación
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
        totalVehiculos: _vehiculos.length,
        asignados: _vehiculos.where((v) => v.estado == 'asignado').length,
        enMantenimiento: _vehiculos.where((v) => v.estado == 'mantenimiento').length,
        disponibles: _vehiculos.where((v) => v.estado == 'disponible').length,
        selectedStatus: _selectedStatus,
        statusOptions: const ['Todos', 'Asignado', 'Disponible', 'Mantenimiento'],
        rows: rows,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onDeleteVehiculo: _promptDeleteVehiculo,
      ),
    );
  }
}
