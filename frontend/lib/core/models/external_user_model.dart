import 'package:cloud_firestore/cloud_firestore.dart';

class ExternalUserModel {
  final String uid;
  final String email;
  final String nombre;
  final String rol;
  final bool datosCompletos;
  final DateTime? createdAt;

  ExternalUserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.datosCompletos,
    this.createdAt,
  });

  factory ExternalUserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    final createdAtValue = map['createdAt'];

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
      rol: (map['rol'] is List && (map['rol'] as List).isNotEmpty)
          ? (map['rol'] as List).first
          : 'invitado',
      datosCompletos: map['datosCompletos'] ?? false,
      createdAt: date,
    );
  }

  @override
  String toString() {
    return 'ExternalUserModel(uid: $uid, email: $email, nombre: $nombre, rol: $rol, datosCompletos: $datosCompletos, createdAt: $createdAt)';
  }
}