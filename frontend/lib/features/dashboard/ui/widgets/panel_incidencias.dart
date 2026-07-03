import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/incidencia_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../incidencias/incidencias_provider.dart';


class PanelIncidencias extends StatelessWidget {
  final bool internalScroll;
  const PanelIncidencias({super.key, this.internalScroll = false});

  String _labelTipo(TipoIncidencia t) => switch (t) {
    TipoIncidencia.averia           => 'Avería',
    TipoIncidencia.accidente        => 'Accidente',
    TipoIncidencia.retraso          => 'Retraso',
    TipoIncidencia.mercancia_danada => 'Mercancía dañada',
    TipoIncidencia.otro             => 'Otro',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidenciaProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incidencias',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
          ),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.incidencias.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Sin incidencias', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Flexible(
              child:  ListView.separated(
                shrinkWrap: !internalScroll,
                physics: internalScroll ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: provider.incidencias.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final inc = provider.incidencias[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _labelTipo(inc.tipo),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM HH:mm').format(inc.fecha),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inc.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}