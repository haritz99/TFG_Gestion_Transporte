import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/carga_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/carga_provider.dart';
import 'form_campos_carga.dart';

class PanelEditarCarga extends StatefulWidget {
  final CargaModel carga;
  final VoidCallback onCerrar;

  const PanelEditarCarga({super.key, required this.carga, required this.onCerrar});

  @override
  State<PanelEditarCarga> createState() => _PanelEditarCargaState();
}

class _PanelEditarCargaState extends State<PanelEditarCarga> {
  final _camposKey = GlobalKey<FormCamposCargaState>();
  bool _guardando = false;

  Future<void> _guardar() async {
    final camposState = _camposKey.currentState;
    if (camposState == null || !camposState.validate()) return;

    setState(() => _guardando = true);
    final campos = camposState.datos;

    try {
      await context.read<CargaProvider>().guardarDetallesCarga(
            cargaId: widget.carga.id!,
            cambios: {
              'tipoEmbalaje': campos.tipoEmbalaje,
              'numBultos': campos.numBultos,
              'peso': campos.peso,
              'volumen': campos.volumen,
              'largo': campos.largo,
              'ancho': campos.ancho,
              'alto': campos.alto,
              'apilable': campos.apilable,
              'precio': campos.precio,
              'origen': campos.origen.toMap(),
              'destino': campos.destino.toMap(),
            },
          );
      if (!mounted) return;
      widget.onCerrar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carga actualizada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los cambios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final carga = widget.carga;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar carga',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.titleText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${carga.id?.toUpperCase()} · ${carga.mercancia}',
                        style: AppTextStyles.bodySm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCerrar,
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const Divider(height: 24),
            FormCamposCarga(key: _camposKey, valorInicial: carga, esEdicion: true),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : widget.onCerrar,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar', style: AppTextStyles.buttonSmall),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}