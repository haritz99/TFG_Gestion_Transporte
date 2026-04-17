import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/transportistas/ui/gestion_equipo_page.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../auth/auth_service.dart';
import '../../vehiculos/providers/vehiculo_provider.dart';
import '../providers/transportista_provider.dart';
import 'models/transportista_row_model.dart';
import 'widgets/confirm_delete_member.dart';
import 'widgets/team_member_form.dart';

class GestionEquipoScreen extends StatelessWidget {
  const GestionEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoProvider(authService: AuthService())),
        ChangeNotifierProvider(create: (_) => TransportistaProvider(authService: AuthService())),
      ],
      child: const _GestionEquipoScreenBody(),
    );
  }
}

class _GestionEquipoScreenBody extends StatefulWidget {
  const _GestionEquipoScreenBody();

  @override
  State<_GestionEquipoScreenBody> createState() => _GestionarEquipoScreenBodyState();
}

class _GestionarEquipoScreenBodyState extends State<_GestionEquipoScreenBody> {
  static const int _pageSize = AppConstants.paginationPageSize;

  final List<UserModel> _transportistas = [];
  bool _firstLoad = true;
  bool _isLoadingPage = false;
  bool _hasMore = true;
  String? _lastDocId;
  String _selectedStatus = 'Todos';

  List<UserModel> get _transportistasFiltrados {
    switch (_selectedStatus) {
      case 'En Ruta':
      case 'Asignado':
      case 'Activo':
        // Por ahora simulamos que estas opciones se cumplen si tienen vehículo
        return _transportistas.where((t) => t.vehiculoId != null && t.vehiculoId!.isNotEmpty).toList();
      case 'Disponible':
        return _transportistas.where((t) => t.vehiculoId == null || t.vehiculoId!.isEmpty).toList();
      case 'Inactivo':
        // Añadir lógica de inactivadad real si la implementas, de momento vacío
        return [];
      default:
        return _transportistas;
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
    final provider = context.read<TransportistaProvider>();
    await provider.fetchEquipoKpis();
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

    final provider = context.read<TransportistaProvider>();
    final response = await provider.fetchEquipoPage(
      limit: _pageSize,
      lastDocId: reset ? null : _lastDocId,
    );

    if (!mounted) return;

    setState(() {
      if (reset) {
        _transportistas
          ..clear()
          ..addAll(response.items);
      } else {
        _transportistas.addAll(response.items);
      }
      _lastDocId = response.lastDocId;
      _hasMore = response.hasMore;
      _isLoadingPage = false;
    });
  }

  Future<void> _handleDesktopPageChanged(int firstRowIndex) async {
    final filteredCount = _transportistas.length;
    if (firstRowIndex + _pageSize > filteredCount && _hasMore) {
      await _loadNextPage();
    }
  }

  Future<void> _promptAddMiembro() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TeamMemberForm(),
    );
    if (result == true && mounted) {
      _lastDocId = null;
      _transportistas.clear();
      _hasMore = true;
      _firstLoad = true;
      _loadInitialData();
    }
  }

  Future<void> _promptEditMiembro(String uid) async {
    final member = _transportistas.firstWhere((t) => t.uid == uid);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TeamMemberForm(member: member),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _promptDeleteMiembro(String uid) async {
    final member = _transportistas.firstWhere((t) => t.uid == uid);
    final fullName = '${member.nombre} ${member.apellido}';
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteMember(uid: uid, nombreCompleto: fullName),
    );
    if (result == true && mounted) {
      // El provider ya remueve de su lista local, pero como guardamos localmente:
      setState(() {
        _transportistas.removeWhere((t) => t.uid == uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportistaProvider>();

    if (_firstLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rows = _transportistasFiltrados.map((t) {
      return TransportistaRowModel(
        uid: t.uid,
        nombre: t.nombre,
        apellido: t.apellido,
        email: t.email,
        telefono: t.telefono,
        rol: t.rol,
        licencias: t.permisosCond,
        cargaAsignada: t.vehiculoId ?? '',
      );
    }).toList();

    return Scaffold(
      body: GestionEquipoPage(
        totalEquipo: provider.totalEquipo ?? 0,
        enRuta: provider.enRuta ?? 0,
        disponibles: provider.disponibles ?? 0,
        inactivos: provider.inactivos ?? 0,
        selectedStatus: _selectedStatus,
        statusOptions: const ['Todos', 'En Ruta', 'Activo', 'Disponible'],
        rows: rows,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingPage,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onAddMiembro: _promptAddMiembro,
        onDeleteMiembro: _promptDeleteMiembro,
        onEditMiembro: _promptEditMiembro,
        onMobileLoadMore: _loadNextPage,
        onDesktopPageChanged: _handleDesktopPageChanged,
      )
    );
  }

}
