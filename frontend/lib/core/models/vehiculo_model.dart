class VehiculoModel {
  final String id;
  final String matricula;
  final String tipo; // 'interno' o 'externo'
  final double capacidad;
  final String? conductorId;

  VehiculoModel({
    required this.id,
    required this.matricula,
    required this.tipo,
    required this.capacidad,
    this.conductorId,
  });

  factory VehiculoModel.fromMap(Map<String, dynamic> map, String id) {
    return VehiculoModel(
      id: id,
      matricula: map['matricula'] ?? '',
      tipo: map['tipo'] ?? '',
      capacidad: (map['capacidad'] ?? 0).toDouble(),
      conductorId: map['conductorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matricula': matricula,
      'tipo': tipo,
      'capacidad': capacidad,
      'conductorId': conductorId,
    };
  }
}
