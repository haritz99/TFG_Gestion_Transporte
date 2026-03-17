class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final List<String> rol;
  final String? vehiculoId;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.vehiculoId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final rawRol = map['rol'];
    final normalizedRol = rawRol is List
        ? rawRol.whereType<String>().toList()
        : (rawRol is String && rawRol.isNotEmpty ? [rawRol] : <String>[]);

    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      rol: normalizedRol,
      vehiculoId: map['vehiculoId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'vehiculoId': vehiculoId,
    };
  }
}
