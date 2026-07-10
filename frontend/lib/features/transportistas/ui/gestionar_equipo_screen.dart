import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/transportistas/ui/gestion_equipo_page.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../core/app_constants.dart';
import '../../../core/models/carga_model.dart';
import '../../../core/models/user_model.dart';
import '../../cargas/providers/carga_provider.dart';
import '../transportista_provider.dart';
import 'models/transportista_row_model.dart';
import 'widgets/confirm_delete_member.dart';
import 'widgets/team_member_form.dart';

class GestionEquipoScreen extends StatelessWidget {
  const GestionEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GestionEquipoScreenBody();
  }
}

class _GestionEquipoScreenBody extends StatefulWidget {
  const _GestionEquipoScreenBody();

  @override
  State<_GestionEquipoScreenBody> createState() => _GestionarEquipoScreenBodyState();
}

class _GestionarEquipoScreenBodyState extends State<_GestionEquipoScreenBody> {
  static const int _pageSize = AppConstants.paginationPageSize;

  TransportistaProvider get _transportistaProvider => context.read<TransportistaProvider>();

  bool _firstLoad = true;
  String _selectedStatus = 'Todos';

  List<UserModel> _filterTransportistas(List<UserModel> source, CargaProvider cargaProvider) {
    if (_selectedStatus == 'Todos') return source;

    return source.where((t) {
      final estado = cargaProvider.estadoConductor(t.uid);
      switch (_selectedStatus) {
        case 'En Ruta':        return estado == 'en_ruta';
        case 'Sin Asignar':    return estado == 'sin_asignar';
        case 'Asignado':       return estado == 'asignado';
        case 'Asignado Parcial': return estado == 'asignacion_parcial';
        default:               return true;
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
    await _transportistaProvider.loadInitialEquipo(limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _firstLoad = false;
    });
  }

  Future<void> _handleDesktopPageChanged(int firstRowIndex) async {
    final filteredCount = _transportistaProvider.transportistas.length;
    if (firstRowIndex + _pageSize > filteredCount && _transportistaProvider.hasMore) {
      await _transportistaProvider.loadNextPage(limit: _pageSize);
    }
  }

  Future<void> _deleteMember(String uid) async {
    final success = await _transportistaProvider.deleteTransportista(uid);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miembro eliminado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_transportistaProvider.errorMessage ?? 'Error al eliminar')),
      );
    }
  }

  Future<void> _promptAddMiembro() async {
    await showDialog<UserModel?>(
      context: context,
      builder: (modalContext) => Dialog(
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: _transportistaProvider,
              child: const TeamMemberForm(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _promptEditMiembro(String uid) async {
    final member = _transportistaProvider.transportistas.firstWhere((t) => t.uid == uid);
    await showDialog<UserModel?>(
      context: context,
      builder: (modalContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: ChangeNotifierProvider.value(
              value: _transportistaProvider,
              child: TeamMemberForm(member: member),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _promptDeleteMiembro(String uid) async {
    final member = _transportistaProvider.transportistas.firstWhere((t) => t.uid == uid);
    final fullName = '${member.nombre} ${member.apellido}';

    await showDialog<void>(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: _transportistaProvider,
        child: ConfirmDeleteMember(
          uid: uid,
          nombreCompleto: fullName,
          onCancel: () => Navigator.of(ctx).pop(),
          onConfirm: () async {
            Navigator.of(ctx).pop();
            await _deleteMember(uid);
          },
        ),
      )
    );
  }

  String _formatEstado(String rawStatus) {
    switch (rawStatus) {
      case 'sin_asignar':
        return 'Sin Asignar';
      case 'asignacion_parcial':
        return 'Asignado Parcial';
      case 'asignado':
        return 'Asignado';
      case 'en_ruta':
        return 'En Ruta';
      case 'inactivo':
        return 'Inactivo';
      default:
        if (rawStatus.isEmpty) return 'Desconocido';
        return rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportistaProvider>();
    final cargaProvider = context.read<CargaProvider>();
    final filtered = _filterTransportistas(provider.transportistas, cargaProvider);

    if (_firstLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rows = filtered.map((t) {
      final cargaActiva = cargaProvider.cargas.firstWhereOrNull((c) =>
      c.transportistaId == t.uid &&
          (c.estado == EstadoCarga.asignado || c.estado == EstadoCarga.enTransito || c.estado == EstadoCarga.planificado));

      return TransportistaRowModel(
        uid: t.uid,
        nombre: t.nombre,
        apellido: t.apellido,
        email: t.email,
        telefono: t.telefono,
        estado: _formatEstado(cargaProvider.estadoConductor(t.uid )),
        licencias: t.permisosCond,
        cargaAsignada: cargaActiva?.id ?? '',
        vehiculoAsignado: cargaActiva?.vehiculoId ?? '',
        fechaDeAlta: t.createdAt,
      );
    }).toList();
    return Scaffold(
      body: GestionEquipoPage(
        selectedStatus: _selectedStatus,
        statusOptions: const ['Todos', 'Sin Asignar', 'En Ruta', 'Asignado', 'Asignado Parcial'],
        rows: rows,
        hasMore: provider.hasMore,
        isLoadingMore: provider.isLoadingPage,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onAddMiembro: _promptAddMiembro,
        onDeleteMiembro: _promptDeleteMiembro,
        onEditMiembro: _promptEditMiembro,
        onMobileLoadMore: () => provider.loadNextPage(limit: _pageSize),
        onDesktopPageChanged: _handleDesktopPageChanged,
      )
    );
  }

}
