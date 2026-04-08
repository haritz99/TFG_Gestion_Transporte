import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/vehiculo_model.dart';
import '../providers/vehiculo_provider.dart';
import 'models/fleet_table_row_model.dart';
import 'gestion_flota_page.dart';
import '../../auth/auth_service.dart';

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
      case 'Activo':
        return _vehiculos.where((v) => v.disponible).toList();
      case 'Inactivo':
        return _vehiculos.where((v) => !v.disponible).toList();
      case 'Disponible':
        return _vehiculos
            .where((v) => v.disponible && v.transportistaId == null)
            .toList();
      case 'Mantenimiento':
        // No existe este campo en VehiculoModel aun.
        return const [];
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
        disponible: v.disponible ? 'Sí' : 'No',
        interno: v.interno ? 'Interno' : 'Subcontratado',
        // Si tienes campos adicionales en el modelo como matriculaRemolque, añádelos aquí
        transportistaAsignado: v.transportistaId ?? 'Sin asignar',
      );
    }).toList();

    return Scaffold(
      body: GestionFlotaPage(
        totalVehiculos: _vehiculos.length,
        activos: _vehiculos.where((v) => v.disponible).length,
        enMantenimiento: 0, // Dato no disponible en VehiculoModel actualmente
        disponibles: _vehiculos.where((v) => v.disponible && v.transportistaId == null).length,
        selectedStatus: _selectedStatus,
        rows: rows,
        onAddVehiculo: () {
          // Lógica para abrir diálogo de creación
        },
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
      ),
    );
  }
}
