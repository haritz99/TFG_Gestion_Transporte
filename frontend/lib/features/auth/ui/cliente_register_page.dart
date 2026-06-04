import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/auth/ui/shared_register.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';

import '../providers/auth_provider.dart';

class ClienteRegisterPage extends StatefulWidget {
  const ClienteRegisterPage({super.key});

  @override
  State<ClienteRegisterPage> createState() => _ClienteRegisterPageState();

}

class _ClienteRegisterPageState extends State<ClienteRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _shared = SharedRegisterControllers();
  final _personaContactoCtr = TextEditingController();

  @override
  void dispose() {
    _shared.dispose();
    _personaContactoCtr.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = ExternalUserProfileUpdateModel(
          nombreComercial: _shared.nombreComercial.text.trim(),
          nif: _shared.nif.text.trim(),
          telefono: _shared.telefono.text.trim(),
          personaContacto: _personaContactoCtr.text.trim().isEmpty ? null : _personaContactoCtr.text.trim(),
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
                    style: AppTextStyles.headingLg,
                  ),
                  const SizedBox(height: 32),

                  RegisterInputField(label: 'Nombre Comercial', hint: 'Nombre comercial', controller: _shared.nombreComercial),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: RegisterInputField(label: 'NIF / CIF', hint: 'B12345678', controller: _shared.nif)),
                      const SizedBox(width: 16),
                      Expanded(child: RegisterInputField(label: 'Teléfono', hint: '+34 600...', controller: _shared.telefono)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  RegisterInputField(label: 'Persona de Contacto', hint: 'Ej. Carlos Ruiz', controller: _personaContactoCtr),
                  const SizedBox(height: 32),

                  const Text('Dirección Fiscal', style: AppTextStyles.headingMd),
                  const SizedBox(height: 16),

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