class CompanyModel {
  final String id;
  final String nombre;
  final int? companyBuffer;

  CompanyModel({
    required this.id,
    required this.nombre,
    this.companyBuffer,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      nombre: map['nombre'] ?? '',
      companyBuffer: map['companyBuffer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? nombre,
    int? bufferHours,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      companyBuffer: bufferHours ?? companyBuffer,
    );
  }
}