import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/models/direccion_model.dart';
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

  final _nombreComercialCtr = TextEditingController();
  final _nifCtr = TextEditingController();
  final _telefonoCtr = TextEditingController();
  final _personaContactoCtr = TextEditingController();
  final _calleCtr = TextEditingController();
  final _ciudadCtr = TextEditingController();
  final _provinciaCtr = TextEditingController();
  final _codigoPostalCtr = TextEditingController();
  final _paisCtr = TextEditingController(text: 'España');

  @override
  void dispose() {
    _nombreComercialCtr.dispose();
    _nifCtr.dispose();
    _telefonoCtr.dispose();
    _personaContactoCtr.dispose();
    _calleCtr.dispose();
    _ciudadCtr.dispose();
    _provinciaCtr.dispose();
    _codigoPostalCtr.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final provider = context.read<AuthProvider>();
        final data = ExternalUserProfileUpdateModel(
          nombreComercial: _nombreComercialCtr.text.trim(),
          nif: _nifCtr.text.trim(),
          telefono: _telefonoCtr.text.trim(),
          personaContacto: _personaContactoCtr.text.trim().isEmpty ? null : _personaContactoCtr.text.trim(),
          direccion: DireccionModel(
            calle: _calleCtr.text.trim(),
            ciudad: _ciudadCtr.text.trim(),
            provincia: _provinciaCtr.text.trim(),
            codigoPostal: _codigoPostalCtr.text.trim(),
            pais: _paisCtr.text.trim().isEmpty ? 'España' : _paisCtr.text.trim(),
          ),
        );
        await provider.fulfillExternalUserProfile(data);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInput(String label, String hint, IconData icon, TextEditingController controller, {bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          //style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: isRequired ? (v) => v!.trim().isEmpty ? 'Campo requerido' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
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

                  _buildInput('Nombre Comercial', 'Nombre comercial', Icons.business, _nombreComercialCtr),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildInput('NIF / CIF', 'B12345678', Icons.badge_outlined, _nifCtr)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput('Teléfono', '+34 600...', Icons.phone_outlined, _telefonoCtr)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildInput('Persona de Contacto', 'Ej. Carlos Ruiz', Icons.person_outline, _personaContactoCtr),
                  const SizedBox(height: 32),

                  const Text('Dirección Fiscal', style: AppTextStyles.headingMd),
                  const SizedBox(height: 16),

                  _buildInput('Calle y número', 'Dirección completa', Icons.location_on_outlined, _calleCtr),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildInput('Ciudad', 'Ciudad', Icons.location_city_outlined, _ciudadCtr)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput('Código Postal', '00000', Icons.markunread_mailbox_outlined, _codigoPostalCtr)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildInput('Provincia', 'Provincia', Icons.map_outlined, _provinciaCtr)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput('País', 'España', Icons.public, _paisCtr)),
                    ],
                  ),
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