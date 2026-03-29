class VehiculoModel {
  final String id;
  final String matricula;
  final String marca;
  final String modelo;
  final double capacidad;
  final double largo;
  final double ancho;
  final double alto;
  final bool disponible;
  final bool interno;
  final String? companyId;
  final String? transportistaId;

  VehiculoModel({
    required this.id,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.capacidad,
    required this.largo,
    required this.ancho,
    required this.alto,
    required this.disponible,
    required this.interno,
    this.companyId,
    this.transportistaId,
  });

  factory VehiculoModel.fromMap(Map<String, dynamic> map, String id) {
    return VehiculoModel(
      id: id,
      matricula: map['matricula'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      capacidad: (map['capacidad'] ?? 0).toDouble(),
      largo: (map['largo'] ?? 0).toDouble(),
      ancho: (map['ancho'] ?? 0).toDouble(),
      alto: (map['alto'] ?? 0).toDouble(),
      disponible: map['disponible'] ?? false,
      interno: map['interno'] ?? false,
      companyId: map['companyId'],
      transportistaId: map['transportistaId'],
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
      'disponible': disponible,
      'interno': interno,
      'companyId': companyId,
      'transportistaId': transportistaId,
    };
  }
}
