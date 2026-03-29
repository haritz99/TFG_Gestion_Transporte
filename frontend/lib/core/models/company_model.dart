class CompanyModel {
  final String id;
  final String nombre;

  CompanyModel({
    required this.id,
    required this.nombre,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
    };
  }
}