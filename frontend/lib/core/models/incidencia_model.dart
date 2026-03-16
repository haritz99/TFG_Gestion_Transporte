import 'package:cloud_firestore/cloud_firestore.dart';

class IncidenciaModel {
  final String id;
  final String descripcion;
  final String conductorId;
  final String? cargaId;
  final DateTime fecha;

  IncidenciaModel({
    required this.id,
    required this.descripcion,
    required this.conductorId,
    this.cargaId,
    required this.fecha,
  });

  factory IncidenciaModel.fromMap(Map<String, dynamic> map, String id) {
    return IncidenciaModel(
      id: id,
      descripcion: map['descripcion'] ?? '',
      conductorId: map['conductorId'] ?? '',
      cargaId: map['cargaId'],
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'conductorId': conductorId,
      'cargaId': cargaId,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}
