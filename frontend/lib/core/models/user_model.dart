class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'encargado' o 'conductor'
  final String? vehiculoId;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.vehiculoId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? '',
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
