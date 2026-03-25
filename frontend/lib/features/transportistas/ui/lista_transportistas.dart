import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:provider/provider.dart';
import '../providers/transportista_provider.dart';

class ListaTransportistasView extends StatefulWidget {
  const ListaTransportistasView({super.key});

  @override
  State<ListaTransportistasView> createState() =>
      _ListaTransportistasViewState();
}

class _ListaTransportistasViewState extends State<ListaTransportistasView> {
  Future<void> _showEditDialog(UserModel t) async {
    final transportistaProvider = context.read<TransportistaProvider>();
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: t.nombre);
    final apellidoCtrl = TextEditingController(text: t.apellido);
    final emailCtrl = TextEditingController(text: t.email);
    final telefonoCtrl = TextEditingController(text: t.telefono);

    final permisos = List<String>.from(t.permisosCond);
    String? selectedPermiso;
    const validPermisos = [
      'AM',
      'A1',
      'A2',
      'A',
      'B1',
      'B',
      'C1',
      'C',
      'D1',
      'D',
      'BE',
      'C1E',
      'CE',
      'D1E',
      'DE',
      'L',
      'T',
    ];

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Editar transportista'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Introduce el nombre' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: apellidoCtrl,
                          decoration: const InputDecoration(labelText: 'Apellido'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Introduce el apellido' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Introduce el email';
                            final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                            if (!regex.hasMatch(value)) return 'Email no valido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: telefonoCtrl,
                          decoration: const InputDecoration(labelText: 'Telefono'),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Introduce el telefono';
                            final regex = RegExp(r'^[0-9]{9}$');
                            if (!regex.hasMatch(value)) return 'Telefono no valido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedPermiso,
                                decoration: const InputDecoration(
                                  labelText: 'Permiso',
                                ),
                                items: validPermisos
                                    .map(
                                      (p) => DropdownMenuItem<String>(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setDialogState(() => selectedPermiso = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: selectedPermiso == null
                                  ? null
                                  : () {
                                      if (!permisos.contains(selectedPermiso)) {
                                        setDialogState(() => permisos.add(selectedPermiso!));
                                      }
                                      setDialogState(() => selectedPermiso = null);
                                    },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            children: permisos
                                .map(
                                  (p) => Chip(
                                    label: Text(p),
                                    onDeleted: () => setDialogState(() => permisos.remove(p)),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (permisos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes añadir al menos un permiso de conducir.'),
                        ),
                      );
                      return;
                    }

                    final ok = await transportistaProvider.updateTransportista(
                      uid: t.uid,
                      nombre: nombreCtrl.text.trim(),
                      apellido: apellidoCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      telefono: telefonoCtrl.text.trim(),
                      rol: t.rol,
                      permisosCond: permisos,
                      vehiculoId: t.vehiculoId,
                    );

                    if (!mounted || !dialogContext.mounted) return;
                    if (ok) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transportista actualizado.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(transportistaProvider.errorMessage ?? 'No se pudo actualizar.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(UserModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar transportista'),
        content: Text(
          'Vas a eliminar a ${t.nombre} ${t.apellido}. Esta accion no se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<TransportistaProvider>();
    final ok = await provider.deleteTransportista(t.uid);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Transportista eliminado correctamente.' : (provider.errorMessage ?? 'No se pudo eliminar.'),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportistaProvider>().fetchTransportistas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportistaProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.transportistas.isEmpty) {
      return const Center(child: Text('No hay transportistas registrados.'));
    }

    return RefreshIndicator(
      onRefresh: context.read<TransportistaProvider>().fetchTransportistas,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: provider.transportistas.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final t = provider.transportistas[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
              title: Text('${t.nombre} ${t.apellido}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${t.email}'),
                  Text('Telefono: ${t.telefono}'),
                  Text('Permisos: ${t.permisosCond.join(', ')}'),
                  Text('Vehiculo: ${t.vehiculoId ?? 'Sin asignar'}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _showEditDialog(t);
                  } else if (value == 'eliminar') {
                    _confirmDelete(t);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'editar',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
