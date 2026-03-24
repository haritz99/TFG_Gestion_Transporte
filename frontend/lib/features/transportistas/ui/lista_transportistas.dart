import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transportista_provider.dart';

class ListaTransportistasView extends StatefulWidget {
  const ListaTransportistasView({super.key});

  @override
  State<ListaTransportistasView> createState() =>
      _ListaTransportistasViewState();
}

class _ListaTransportistasViewState extends State<ListaTransportistasView> {
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

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.transportistas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = provider.transportistas[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_shipping),
            title: Text('${t.nombre} ${t.apellido}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${t.email}'),
                Text('Telefono: ${t.telefono}'),
                Text('Permisos: ${t.permisosCond.join(', ')}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
