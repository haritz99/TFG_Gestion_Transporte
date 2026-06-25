import 'model_utils.dart';
enum TipoIncidencia { averia, accidente, retraso, mercancia_danada, otro }
class IncidenciaModel {
  final String id;
  final String descripcion;
  final String conductorId;
  final String? cargaId;
  final String? companyId;
  final DateTime fecha;
  final TipoIncidencia tipo;
  final bool resuelta;


  IncidenciaModel({
    required this.id,
    required this.descripcion,
    required this.conductorId,
    this.cargaId,
    required this.companyId,
    required this.fecha,
    required this.tipo,
    required this.resuelta,
  });

  factory IncidenciaModel.fromMap(Map<String, dynamic> map, String id) {
    return IncidenciaModel(
      id: id,
      descripcion: map['descripcion'] ?? '',
      conductorId: map['conductorId'] ?? '',
      cargaId: map['cargaId'],
      companyId: map['companyId'] ?? '',
      fecha: ModelUtils.parseDateTime(map['createdAt']) ?? DateTime.now(),
      tipo: TipoIncidencia.values.firstWhere((e) => e.name == map['tipo'], orElse: () => TipoIncidencia.otro),
      resuelta: map['resuelta'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'descripcion': descripcion,
    };
  }
}
