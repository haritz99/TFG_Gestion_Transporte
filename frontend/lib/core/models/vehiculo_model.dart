class VehiculoModel {
  final String matricula;
  final String marca;
  final String modelo;
  final double capacidad;
  final double largo;
  final double ancho;
  final double alto;
  final String estado;
  final bool interno;
  final String? matriculaRemolque;
  final String? companyId;
  final String? transportistaId;
  final String? transportistaNombre;

  VehiculoModel({
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.capacidad,
    required this.largo,
    required this.ancho,
    required this.alto,
    required this.estado,
    required this.interno,
    this.matriculaRemolque,
    this.companyId,
    this.transportistaId,
    this.transportistaNombre,
  });

  factory VehiculoModel.fromMap(Map<String, dynamic> map, String id) {
    return VehiculoModel(
      matricula: map['matricula'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      capacidad: (map['capacidad'] ?? 0).toDouble(),
      largo: (map['largo'] ?? 0).toDouble(),
      ancho: (map['ancho'] ?? 0).toDouble(),
      alto: (map['alto'] ?? 0).toDouble(),
      estado: map['estado'] ?? '',
      interno: map['interno'] ?? false,
      matriculaRemolque: map['matriculaRemolque'],
      companyId: map['companyId'],
      transportistaId: map['transportistaId'],
      transportistaNombre: map['transportistaNombre'],
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
      'estado': estado,
      'interno': interno,
      'matriculaRemolque': matriculaRemolque,
      'companyId'
      'companyId': companyId,
      'transportistaId': transportistaId,
    };
  }
}
