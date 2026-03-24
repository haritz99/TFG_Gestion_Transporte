import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_service.dart';
import '../providers/transportista_provider.dart';

class GestionarTransportistas extends StatelessWidget {
  const GestionarTransportistas({super.key});

  @override
  Widget build(BuildContext context) {
	return ChangeNotifierProvider(
	  create: (_) => TransportistaProvider(authService: AuthService()),
	  child: const _GestionarTransportistasView(),
	);
  }
}

class _GestionarTransportistasView extends StatefulWidget {
  const _GestionarTransportistasView();

  @override
  State<_GestionarTransportistasView> createState() =>
	  _GestionarTransportistasViewState();
}

class _GestionarTransportistasViewState
	extends State<_GestionarTransportistasView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final List<String> _permisosList = [];
  
  String? _selectedPermiso;
  static const List<String> _validPermisos = [
    'AM', 'A1', 'A2', 'A', 'B1', 'B', 'C1', 'C', 'D1', 'D',
    'BE', 'C1E', 'CE', 'D1E', 'DE', 'L', 'T',
  ];

  @override
  void dispose() {
	_nombreCtrl.dispose();
	_apellidoCtrl.dispose();
	_emailCtrl.dispose();
	_telefonoCtrl.dispose();
	super.dispose();
  }

  void _addPermiso() {
    if (_selectedPermiso != null && !_permisosList.contains(_selectedPermiso)) {
      setState(() {
        _permisosList.add(_selectedPermiso!);
        _selectedPermiso = null;
      });
    }
  }

  void _removePermiso(String p) {
    setState(() {
      _permisosList.remove(p);
    });
  }

  Future<void> _onSubmit() async {
	if (!_formKey.currentState!.validate()) return;

	final provider = context.read<TransportistaProvider>();
	final ok = await provider.createTransportista(
	  nombre: _nombreCtrl.text.trim(),
	  apellido: _apellidoCtrl.text.trim(),
	  email: _emailCtrl.text.trim(),
	  telefono: _telefonoCtrl.text.trim(),
	  permisosCond: _permisosList,
	);

	if (!mounted) return;

	if (ok) {
	  ScaffoldMessenger.of(context).showSnackBar(
		const SnackBar(content: Text('Transportista creado correctamente.')),
	  );
	  _formKey.currentState?.reset();
	  _nombreCtrl.clear();
	  _apellidoCtrl.clear();
	  _emailCtrl.clear();
	  _telefonoCtrl.clear();
	  setState(() {
	    _permisosList.clear();
        _selectedPermiso = null;
	  });
	}
  }

  @override
  Widget build(BuildContext context) {
	final provider = context.watch<TransportistaProvider>();

	return Scaffold(
	  appBar: AppBar(title: const Text('Gestionar transportistas')),
	  body: SingleChildScrollView(
		padding: const EdgeInsets.all(16),
		child: Form(
		  key: _formKey,
		  child: Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
			  TextFormField(
				controller: _nombreCtrl,
				decoration: const InputDecoration(
				  labelText: 'Nombre',
				  border: OutlineInputBorder(),
				),
				validator: (v) {
				  if (v == null || v.trim().isEmpty) {
					return 'Introduce el nombre';
				  }
				  return null;
				},
			  ),
			  const SizedBox(height: 12),
			  TextFormField(
				controller: _apellidoCtrl,
				decoration: const InputDecoration(
				  labelText: 'Apellido',
				  border: OutlineInputBorder(),
				),
				validator: (v) {
				  if (v == null || v.trim().isEmpty) {
					return 'Introduce el apellido';
				  }
				  return null;
				},
			  ),
			  const SizedBox(height: 12),
			  TextFormField(
				controller: _emailCtrl,
				keyboardType: TextInputType.emailAddress,
				decoration: const InputDecoration(
				  labelText: 'Email',
				  border: OutlineInputBorder(),
				),
				validator: (v) {
				  final value = v?.trim() ?? '';
				  if (value.isEmpty) return 'Introduce el email';
				  final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
				  if (!regex.hasMatch(value)) return 'Email no valido';
				  return null;
				},
			  ),
			  const SizedBox(height: 12),
			  TextFormField(
				controller: _telefonoCtrl,
				keyboardType: TextInputType.phone,
				decoration: const InputDecoration(
				  labelText: 'Telefono',
				  border: OutlineInputBorder(),
				),
				validator: (v) {
				  if (v == null || v.trim().isEmpty) {
					return 'Introduce el telefono';
				  }
					final regex = RegExp(r'^[0-9]{9}$');
					if (!regex.hasMatch(v)) return 'Telefono no valido';
				  return null;
				},
			  ),
			  const SizedBox(height: 12),
			  FormField<List<String>>(
				validator: (_) {
				  if (_permisosList.isEmpty) {
					return 'Debes añadir al menos un permiso de conducir';
				  }
				  return null;
				},
				builder: (FormFieldState<List<String>> state) {
				  return Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
					  Row(
						children: [
						  Expanded(
							child: DropdownButtonFormField<String>(
							  initialValue: _selectedPermiso,
							  decoration: const InputDecoration(
								labelText: 'Permiso (Seleccionar)',
								border: OutlineInputBorder(),
							  ),
							  items: _validPermisos
								  .map((p) => DropdownMenuItem(
										value: p,
										child: Text(p),
									  ))
								  .toList(),
							  onChanged: (v) =>
								  setState(() => _selectedPermiso = v),
							),
						  ),
						  const SizedBox(width: 8),
						  IconButton.filled(
							onPressed: _selectedPermiso == null
								? null
								: () {
									_addPermiso();
									state.didChange(_permisosList);
								  },
							icon: const Icon(Icons.add),
						  ),
						],
					  ),
					  if (_permisosList.isNotEmpty)
						Padding(
						  padding: const EdgeInsets.symmetric(vertical: 8),
						  child: Wrap(
							spacing: 8,
							children: _permisosList
								.map((p) => Chip(
									  label: Text(p),
									  onDeleted: () {
										_removePermiso(p);
										state.didChange(_permisosList);
									  },
									))
								.toList(),
						  ),
						),
					  if (state.hasError)
						Padding(
						  padding: const EdgeInsets.only(top: 6, left: 12),
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
			  const SizedBox(height: 16),
			  if (provider.errorMessage != null)
				Padding(
				  padding: const EdgeInsets.only(bottom: 12),
				  child: Text(
					provider.errorMessage!,
					style: const TextStyle(color: Colors.red),
				  ),
				),
			  FilledButton(
				onPressed: provider.isLoading ? null : _onSubmit,
				child: provider.isLoading
					? const SizedBox(
						width: 18,
						height: 18,
						child: CircularProgressIndicator(strokeWidth: 2),
					  )
					: const Text('Crear transportista'),
			  ),
			  const SizedBox(height: 10),
			  OutlinedButton.icon(
				onPressed: provider.createResponse == null || provider.isLoading
					? null
					: () async {
						final sent = await context
							.read<TransportistaProvider>()
							.sendCredentialsEmail();
						if (!mounted) return;
						ScaffoldMessenger.of(context).showSnackBar(
						  SnackBar(
							content: Text(
							  sent
								  ? 'Se abrio la app de correo para enviar credenciales.'
								  : (provider.errorMessage ??
									  'No se pudo preparar el correo.'),
							),
						  ),
						);
					  },
				icon: const Icon(Icons.share),
				label: const Text('Compartir credenciales por correo'),
			  ),
			],
		  ),
		),
	  ),
	);
  }
}