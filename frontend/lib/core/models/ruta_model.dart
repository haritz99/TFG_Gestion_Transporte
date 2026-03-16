import 'package:cloud_firestore/cloud_firestore.dart';

class RutaModel {
  final String id;
  final String cargaId;
  final String conductorId;
  final String origen;
  final String destino;
  final double? distanciaKm;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  RutaModel({
    required this.id,
    required this.cargaId,
    required this.conductorId,
    required this.origen,
    required this.destino,
    this.distanciaKm,
    required this.fechaInicio,
    this.fechaFin,
  });

  factory RutaModel.fromMap(Map<String, dynamic> map, String id) {
    return RutaModel(
      id: id,
      cargaId: map['cargaId'] ?? '',
      conductorId: map['conductorId'] ?? '',
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      distanciaKm: map['distanciaKm']?.toDouble(),
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaFin: map['fechaFin'] != null
          ? (map['fechaFin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cargaId': cargaId,
      'conductorId': conductorId,
      'origen': origen,
      'destino': destino,
      'distanciaKm': distanciaKm,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
    };
  }
}
