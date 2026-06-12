import 'package:cloud_firestore/cloud_firestore.dart';

import 'direccion_model.dart';

class ExternalUserModel {
  final String uid;
  final String email;
  final String nombre;
  final List<String> rol;
  final bool datosCompletos;
  final String companyId;
  final bool activo;
  final DateTime? createdAt;
  final List<String> cargasCedidas;


  ExternalUserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.datosCompletos,
    required this.companyId,
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
      companyId: map['companyId'] ?? '',
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
      'companyId': companyId,
      'activo': activo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'cargasCedidas': cargasCedidas,
    };
  }
}

class ExternalUserProfileUpdateModel {
  final String nombreComercial;
  final String nif;
  final String telefono;
  final String? personaContacto;
  final String? razonSocial;
  final String? numeroAutorizacion;
  final DireccionModel direccion;

  const ExternalUserProfileUpdateModel({
    required this.nombreComercial,
    required this.nif,
    required this.telefono,
    required this.direccion,
    this.personaContacto,
    this.razonSocial,
    this.numeroAutorizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombreComercial': nombreComercial,
      'nif': nif,
      'telefono': telefono,
      if (personaContacto != null) 'personaContacto': personaContacto,
      if (razonSocial != null) 'razonSocial': razonSocial,
      if (numeroAutorizacion != null) 'numeroAutorizacion': numeroAutorizacion,
      'direccionFiscal': direccion.toMap(),
    };
  }
}