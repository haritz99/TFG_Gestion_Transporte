import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _inactivo = false;

  final List<String> _licenciasOptions = [
    'C1', 'C', 'D1', 'D', 'BE', 'C1E', 'CE', 'D1E', 'DE',
  ];

  bool _isCreated = false;
  UserModel? _createdUser;

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
      _vehiculoId = widget.member!.vehiculoId;
      _cargaId = widget.member!.cargaId;
      _inactivo = widget.member!.estado == 'inactivo';
    } else {
      _nombre = '';
      _apellido = '';
      _email = '';
      _telefono = '';
      _vehiculoId = null;
      _cargaId = null;
      _inactivo = false;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = context.read<TransportistaProvider>();

      String vId = _vehiculoId?.trim() ?? '';
      String cId = _cargaId?.trim() ?? '';

      String finalVehiculoId = vId.isNotEmpty ? vId : '';
      String finalCargaId = cId.isNotEmpty ? cId : '';

      String nuevoEstado = 'sin_asignar';
      if (_inactivo) {
        nuevoEstado = 'inactivo';
      } else {
        if (finalVehiculoId.isNotEmpty && finalCargaId.isNotEmpty) {
          nuevoEstado = 'asignado';
        } else if (finalVehiculoId.isNotEmpty || finalCargaId.isNotEmpty) {
          nuevoEstado = 'asignacion_parcial';
        }
      }

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
          vehiculoId: finalVehiculoId.isNotEmpty ? finalVehiculoId : null,
          cargaId: finalCargaId.isNotEmpty ? finalCargaId : null,
          estado: nuevoEstado,
        );
      }

      if (mounted) {
        if (result != null) {
          if (widget.member == null) {
            _createdUser = result;
            setState(() {
              _isCreated = true;
            });
          } else {
            Navigator.of(context).pop(result);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? 'Error al guardar')),
          );
        }
      }
    }
  }

  void _sendEmail() async {
    final provider = context.read<TransportistaProvider>();
    bool success = await provider.sendCredentialsEmail();

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(_createdUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Error al enviar credenciales')),
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
                      onSaved: (value) => _nombre = value!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _apellido,
                      decoration: const InputDecoration(labelText: 'Apellido'),
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
                        onSaved: (value) => _vehiculoId = value,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _cargaId,
                        decoration: const InputDecoration(labelText: 'ID Carga'),
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
                    child: Text(_isCreated ? 'Cerrar' : 'Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  if (_isCreated && widget.member == null)
                    ElevatedButton(
                      onPressed: _sendEmail,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Enviar credenciales'),
                    )
                  else ...[
                    if (context.watch<TransportistaProvider>().isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('Guardar'),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
