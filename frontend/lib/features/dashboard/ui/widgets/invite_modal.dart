import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/invite_provider.dart';

class InviteModal extends StatefulWidget {
  const InviteModal({super.key});

  @override
  State<InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<InviteModal> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _rol = 'cliente';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = context.read<InviteProvider>();

      try {
        await provider.createUser(_email, _rol);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear usuario: $e')),
          );
        }
      }
    }
  }

  void _sendEmail() async {
    final provider = context.read<InviteProvider>();
    final success = await provider.sendInviteEmail(_email, _rol);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación de correo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InviteProvider>();
    final isCreated = provider.isCreated;
    final isLoading = provider.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invita a un colaborador',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Envía una invitación para colaborar en la plataforma.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Introduce el email';
                  final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
                  if (!regex.hasMatch(v)) return 'Email no válido';
                  return null;
                },
                onSaved: (value) => _email = value!.trim(),
                enabled: !isCreated && !isLoading,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cliente',
                    child: Text('Cargador'),
                  ),
                  DropdownMenuItem(
                    value: 'subcontratado',
                    child: Text('Subcontratado'),
                  ),
                ],
                onChanged: isCreated || isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _rol = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isCreated ? 'Cerrar' : 'Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  if (isCreated)
                    ElevatedButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar invitación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Crear Enlace'),
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

