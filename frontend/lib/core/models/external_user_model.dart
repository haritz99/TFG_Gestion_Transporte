import 'package:cloud_firestore/cloud_firestore.dart';

class ExternalUserModel {
  final String uid;
  final String email;
  final String nombre;
  final List<String> rol;
  final bool datosCompletos;
  final bool activo;
  final DateTime? createdAt;
  final List<String> cargasCedidas;

  ExternalUserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.datosCompletos,
    this.activo = true,
    this.createdAt,
    this.cargasCedidas = const [],
  });

  factory ExternalUserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    final createdAtValue = map['createdAt'];

    final rawRol = map['rol'];
    final List<String> normalizedRol = rawRol == null
        ? <String>[]
        : (rawRol is List ? List<String>.from(rawRol) : [rawRol.toString()]);

    final List<String> cargasCedidas = map['cargasCedidas'] != null
        ? List<String>.from(map['cargasCedidas'])
        : [];

    if (createdAtValue != null) {
      if (createdAtValue is String) {
        date = DateTime.tryParse(createdAtValue);
      } else if (createdAtValue is Timestamp) {
        date = createdAtValue.toDate();
      }
    }

    return ExternalUserModel(
      uid: id,
      email: map['email'] ?? '',
      nombre: map['nombreComercial'] ?? 'Sin nombre',
      rol: normalizedRol,
      datosCompletos: map['datosCompletos'] ?? false,
      activo: map['activo'] ?? true,
      createdAt: date,
      cargasCedidas: cargasCedidas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombreComercial': nombre,
      'rol': rol,
      'datosCompletos': datosCompletos,
      'activo': activo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'cargasCedidas': cargasCedidas,
    };
  }
}