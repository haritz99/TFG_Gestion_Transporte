class VehiculoModel {
  final String matricula;
  final String marca;
  final String modelo;
  final double capacidad;
  final double largo;
  final double ancho;
  final double alto;
  final String? matriculaRemolque;
  final String? companyId;

  VehiculoModel({
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.capacidad,
    required this.largo,
    required this.ancho,
    required this.alto,
    this.matriculaRemolque,
    this.companyId,
  });

  @override
  bool operator ==(Object other) => other is VehiculoModel && other.matricula == matricula;

  @override
  int get hashCode => matricula.hashCode;

  factory VehiculoModel.fromMap(Map<String, dynamic> map, String id) {
    return VehiculoModel(
      matricula: map['matricula'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      capacidad: (map['capacidad'] ?? 0).toDouble(),
      largo: (map['largo'] ?? 0).toDouble(),
      ancho: (map['ancho'] ?? 0).toDouble(),
      alto: (map['alto'] ?? 0).toDouble(),
      matriculaRemolque: map['matriculaRemolque'],
      companyId: map['companyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matricula': matricula,
      'marca': marca,
      'modelo': modelo,
      'capacidad': capacidad,
      'largo': largo,
      'ancho': ancho,
      'alto': alto,
    };
  }
}
