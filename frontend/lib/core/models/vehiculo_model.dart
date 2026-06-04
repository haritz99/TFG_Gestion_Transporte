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
  final String? cargaId;

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
    this.cargaId,
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
      estado: map['estado'] ?? '',
      interno: map['interno'] ?? false,
      matriculaRemolque: map['matriculaRemolque'],
      companyId: map['companyId'],
      transportistaId: map['transportistaId'],
      transportistaNombre: map['transportistaNombre'],
      cargaId: map['cargaId'],
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
      'matriculaRemolque': matriculaRemolque?.isEmpty == true ? null : matriculaRemolque,
      'companyId': companyId?.isEmpty == true ? null : companyId,
      'transportistaId': transportistaId?.isEmpty == true ? null : transportistaId,
      'transportistaNombre': transportistaNombre?.isEmpty == true ? null : transportistaNombre,
      'cargaId': cargaId?.isEmpty == true ? null : cargaId,
    };
  }
}
