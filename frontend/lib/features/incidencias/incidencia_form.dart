import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/carga_model.dart';
import '../../core/models/incidencia_model.dart';
import 'incidencias_provider.dart';

void mostrarFormIncidencia(BuildContext context, CargaModel carga) {
  TipoIncidencia tipo = TipoIncidencia.otro;
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Nueva incidencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TipoIncidencia>(
              initialValue: tipo,
              items: TipoIncidencia.values.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t.name))
              ).toList(),
              onChanged: (v) => setState(() => tipo = v!),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await context.read<IncidenciaProvider>().createIncidencia(
                cargaId: carga.id ?? '',
                tipo: tipo,
                descripcion: controller.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    ),
  );
}