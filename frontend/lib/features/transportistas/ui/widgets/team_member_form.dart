import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cargas/providers/carga_provider.dart';
import '../../providers/transportista_provider.dart';

class TeamMemberForm extends StatefulWidget {
  final UserModel? member;

  const TeamMemberForm({super.key, this.member});

  @override
  State<TeamMemberForm> createState() => _TeamMemberFormState();
}

class _TeamMemberFormState extends State<TeamMemberForm> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _apellido;
  late String _email;
  late String _telefono;
  List<String> _rol = ['transportista'];
  List<String> _licencias = [];
  String? _vehiculoId;
  String? _cargaId;

  final List<String> _licenciasOptions = [
    'C1', 'C', 'D1', 'D', 'BE', 'C1E', 'CE', 'D1E', 'DE',
  ];


  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nombre = widget.member!.nombre;
      _apellido = widget.member!.apellido;
      _email = widget.member!.email;
      _telefono = widget.member!.telefono;
      _rol = List.from(widget.member!.rol);
      _licencias = List.from(widget.member!.permisosCond);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cargaProvider = context.read<CargaProvider>();
        final cargaActiva = cargaProvider.cargas.firstWhereOrNull((c) =>
        c.transportistaId == widget.member!.uid &&
            (c.estado == EstadoCarga.asignado ||
                c.estado == EstadoCarga.enTransito ||
                c.estado == EstadoCarga.planificado)
        );
        setState(() {
          _vehiculoId = cargaActiva?.vehiculoId;
          _cargaId = cargaActiva?.id;
        });
      });
    } else {
      _nombre = '';
      _apellido = '';
      _email = '';
      _telefono = '';
      _vehiculoId = null;
      _cargaId = null;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = context.read<TransportistaProvider>();

      UserModel? result;
      if (widget.member == null) {
        result = await provider.createTransportista(
          nombre: _nombre,
          apellido: _apellido,
          email: _email,
          telefono: _telefono,
          rol: _rol,
          permisosCond: _licencias,
        );
      } else {
        result = await provider.updateTransportista(
          uid: widget.member!.uid,
          nombre: _nombre,
          apellido: _apellido,
          email: _email,
          telefono: _telefono,
          rol: _rol,
          permisosCond: _licencias,
        );
      }

      if (!mounted) return;
      if (result != null) {
            Navigator.of(context).pop(result);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Conductor invitado con éxito')),
            );
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? 'Error al guardar')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Miembro' : 'Añadir Miembro',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _nombre,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      enabled: widget.member == null,
                      onSaved: (value) => _nombre = value!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _apellido,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      enabled: widget.member == null,
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      onSaved: (value) => _apellido = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Introduce el email';
                  final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                  if (!regex.hasMatch(v)) return 'Email no válido';
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce el teléfono';
                  }
                  final regex = RegExp(r'^[0-9]{9}$');
                  if (!regex.hasMatch(value)) return 'Teléfono no válido (9 dígitos)';
                  return null;
                },
                onSaved: (value) => _telefono = value!,
              ),
              const SizedBox(height: 16),
              const Text('Licencias'),
              FormField<List<String>>(
                initialValue: _licencias,
                validator: (val) {
                  if (_licencias.isEmpty) {
                    return 'Debes añadir al menos una licencia';
                  }
                  return null;
                },
                builder: (FormFieldState<List<String>> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _licenciasOptions.map((lic) {
                          return FilterChip(
                            label: Text(lic),
                            selected: _licencias.contains(lic),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _licencias.add(lic);
                                } else {
                                  _licencias.remove(lic);
                                }
                              });
                              state.didChange(_licencias);
                            },
                          );
                        }).toList(),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Text('Asignaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _vehiculoId,
                        decoration: const InputDecoration(labelText: 'Matrícula Vehículo'),
                        enabled: false,
                        onSaved: (value) => _vehiculoId = value,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _cargaId,
                        decoration: const InputDecoration(labelText: 'ID Carga'),
                        enabled: false,
                        onSaved: (value) => _cargaId = value,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
