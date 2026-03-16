import 'package:cloud_firestore/cloud_firestore.dart';

class CargaModel {
  final String id;
  final String descripcion;
  final String origen;
  final String destino;
  final String conductorId;
  final String vehiculoId;
  final String estado; // 'pendiente', 'recogida', 'entregada'
  final DateTime fechaCreacion;

  CargaModel({
    required this.id,
    required this.descripcion,
    required this.origen,
    required this.destino,
    required this.conductorId,
    required this.vehiculoId,
    required this.estado,
    required this.fechaCreacion,
  });

  factory CargaModel.fromMap(Map<String, dynamic> map, String id) {
    return CargaModel(
      id: id,
      descripcion: map['descripcion'] ?? '',
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      conductorId: map['conductorId'] ?? '',
      vehiculoId: map['vehiculoId'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'origen': origen,
      'destino': destino,
      'conductorId': conductorId,
      'vehiculoId': vehiculoId,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }
}
