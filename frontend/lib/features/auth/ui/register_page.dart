import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/auth/ui/shared_register.dart';
import 'package:provider/provider.dart';

import 'package:gestion_transporte/features/auth/providers/auth_provider.dart';

import 'company_register_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nombreEmpresaController = TextEditingController();
  bool _isTransportista = false;

  final _shared = SharedRegisterControllers();
  final _razonSocialCtr = TextEditingController();
  final _numAutorizacionCtr = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreEmpresaController.dispose();
    _shared.dispose();
    _razonSocialCtr.dispose();
    _numAutorizacionCtr.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
      return;
    }
    if (_currentStep == 1) {
      _register();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _register() async {
    if (!_formKey2.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    try {
      final roles = ['encargado'];
      if (_isTransportista) {
        roles.add('transportista');
      }

      await authProvider.register(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          email: _emailController.text.trim(),
          telefono: _telefonoController.text.trim(),
          rol: roles,
          permisosCond: [],
          password: _passwordController.text.trim(),
          nombreEmpresa: _shared.nombreComercial.text.trim(),
          razonSocial: _razonSocialCtr.text.trim().isEmpty ? null : _razonSocialCtr.text.trim(),
          nif: _shared.nif.text.trim(),
          telefonoEmpresa: _shared.telefono.text.trim(),
          numAutorizacion: _numAutorizacionCtr.text.trim(),
          direccion: _shared.getDireccionModel(),
          estado: 'disponible'
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrarse: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: authProvider.isLoading ? null : _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) =>
                Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: authProvider.isLoading ? null : details
                                .onStepContinue,
                            child: authProvider.isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(
                                _currentStep == 0 ? 'Siguiente' : 'Registrarme'),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Atrás'),
                          ),
                        ],
                      ],
                    )
                ),
            steps: [
              Step(
                title: const Text('Datos personales'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Form(
                    key: _formKey1,
                    child: _PersonalDataStep(
                      nombreController: _nombreController,
                      apellidoController: _apellidoController,
                      emailController: _emailController,
                      telefonoController: _telefonoController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isTransportista: _isTransportista,
                      onTransportistaChanged: (value) =>
                          setState(() => _isTransportista = value ?? false),
                    )
                ),
              ),
              Step(
                title: const Text('Registra tu empresa'),
                isActive: _currentStep >= 1,
                state: StepState.indexed,
                content: Form(
                  key: _formKey2,
                  child: CompanyRegisterPage(
                    shared: _shared,
                    razonSocialCtr: _razonSocialCtr,
                    numAutorizacionCtr: _numAutorizacionCtr,
                  ),
                ),
              ),
            ],
          ),
        ),
      )

    );
  }
}

class _PersonalDataStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isTransportista;
  final ValueChanged<bool?> onTransportistaChanged;

  const _PersonalDataStep({
    required this.nombreController,
    required this.apellidoController,
    required this.emailController,
    required this.telefonoController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isTransportista,
    required this.onTransportistaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nombreController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Introduce tu nombre';
            if (v.trim().length < 3) return 'Mínimo 3 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: apellidoController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Apellido',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Introduce tu apellido';
            if (v.trim().length < 3) return 'Mínimo 3 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Introduce tu email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
              return 'Email no válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: telefonoController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Introduce tu teléfono';
            if (!RegExp(r'^[0-9]{9}$').hasMatch(v.trim())) {
              return '9 dígitos numéricos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Introduce una contraseña';
            if (v.length < 8) return 'Mínimo 8 caracteres';
            if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe contener una mayúscula';
            if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Confirmar contraseña',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirma tu contraseña';
            if (v != passwordController.text) return 'Las contraseñas no coinciden';
            return null;
          },
        ),
        CheckboxListTile(
          title: const Text('También soy transportista'),
          value: isTransportista,
          onChanged: onTransportistaChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
