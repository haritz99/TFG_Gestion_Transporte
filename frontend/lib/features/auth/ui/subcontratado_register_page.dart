import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/auth/ui/shared_register.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';

import '../providers/auth_provider.dart';

class SubcontratadoRegisterPage extends StatefulWidget {
  const SubcontratadoRegisterPage({super.key});

  @override
  State<SubcontratadoRegisterPage> createState() => _SubcontratadoRegisterPageState();
}

class _SubcontratadoRegisterPageState extends State<SubcontratadoRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _shared = SharedRegisterControllers();
  final _razonSocialCtr = TextEditingController();
  final _numAutorizacionCtr = TextEditingController();

  @override
  void dispose() {
    _shared.dispose();
    _razonSocialCtr.dispose();
    _numAutorizacionCtr.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = ExternalUserProfileUpdateModel(
          nombreComercial: _shared.nombreComercial.text.trim(),
          razonSocial: _razonSocialCtr.text.trim().isEmpty ? null : _razonSocialCtr.text.trim(),
          nif: _shared.nif.text.trim(),
          telefono: _shared.telefono.text.trim(),
          numeroAutorizacion: _numAutorizacionCtr.text.trim(),
          direccion: _shared.getDireccionModel(),
        );
        await context.read<AuthProvider>().fulfillExternalUserProfile(data);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aún te quedan datos por rellenar para entrar en la aplicación!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 32),

                  RegisterInputField(label: 'Nombre Comercial', hint: 'Nombre Comercial', icon: Icons.local_shipping_outlined, controller: _shared.nombreComercial),                  const SizedBox(height: 16),

                  RegisterInputField(label: 'Razón Social', hint: 'Ej. Trans S.L. (si aplica)', icon: Icons.business, controller: _razonSocialCtr, isRequired: false),                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: RegisterInputField(label: 'NIF', hint: '12345678Z', icon: Icons.badge_outlined, controller: _shared.nif)),
                      const SizedBox(width: 16),
                      Expanded(child: RegisterInputField(label: 'Teléfono', hint: '+34 600...', icon: Icons.phone_outlined, controller: _shared.telefono)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  RegisterInputField(label: 'Nº Autorización (LOTT)', hint: 'Obligatorio', icon: Icons.verified_user_outlined, controller: _numAutorizacionCtr),                  const SizedBox(height: 32),

                  DireccionFormSection(shared: _shared),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCA311),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Completar y entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

