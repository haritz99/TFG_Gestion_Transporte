import 'model_utils.dart';

class UserModel {
  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final List<String> rol;
  final List<String> permisosCond;
  final String companyId;
  final String? estado;
  final String? vehiculoId;
  final String? cargaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.permisosCond,
    required this.companyId,
    this.estado,
    this.vehiculoId,
    this.cargaId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final rawRol = map['rol'];
    final normalizedRol = rawRol is List
        ? rawRol.whereType<String>().toList()
        : (rawRol is String && rawRol.isNotEmpty ? [rawRol] : <String>[]);

    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      rol: normalizedRol,
      permisosCond: List<String>.from(map['permisosCond'] ?? []),
      companyId: map['companyId'] ?? '',
      estado: map['estado'] ?? '',
      vehiculoId: map['vehiculoId'],
      cargaId: map['cargaId'],
      createdAt: ModelUtils.parseDateTime(map['createdAt']),
      updatedAt: ModelUtils.parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'permisosCond': permisosCond,
      'companyId': companyId,
      'estado': estado,
      'vehiculoId': vehiculoId,
      'cargaId': cargaId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
