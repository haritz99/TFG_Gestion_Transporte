import 'package:cloud_firestore/cloud_firestore.dart';

class CargaModel {
  final String id;
  final String origen;
  final String destino;
  final String mercancia;
  final int numBultos;
  final double peso;
  final double? largo;
  final double? ancho;
  final double? alto;
  final String estado; // 'pendiente', 'asignado', 'en_transito', 'entregado'
  final DateTime fechaCarga;
  final DateTime fechaDescarga;
  final String? transportistaId;
  final String? pedidoId;
  final String? vehiculoId;
  final String? rutaId;
  final String? companyId;
  final String? clienteId;
  final DateTime fechaCreacion;

  CargaModel({
    required this.id,
    required this.origen,
    required this.destino,
    required this.mercancia,
    required this.numBultos,
    required this.peso,
    this.largo,
    this.ancho,
    this.alto,
    required this.estado,
    required this.fechaCarga,
    required this.fechaDescarga,
    this.transportistaId,
    this.pedidoId,
    this.vehiculoId,
    this.rutaId,
    this.companyId,
    this.clienteId,
    required this.fechaCreacion,
  });

  factory CargaModel.fromMap(Map<String, dynamic> map, String id) {
    return CargaModel(
      id: id,
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      mercancia: map['mercancia'] ?? '',
      numBultos: map['numBultos']?.toInt() ?? 0,
      peso: (map['peso'] ?? 0).toDouble(),
      largo: map['largo'] != null ? (map['largo'] as num).toDouble() : null,
      ancho: map['ancho'] != null ? (map['ancho'] as num).toDouble() : null,
      alto: map['alto'] != null ? (map['alto'] as num).toDouble() : null,
      estado: map['estado'] ?? 'pendiente',
      fechaCarga: map['fechaCarga'] != null
          ? (map['fechaCarga'] as Timestamp).toDate()
          : DateTime.now(),
      fechaDescarga: map['fechaDescarga'] != null
          ? (map['fechaDescarga'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 1)),
      transportistaId: map['transportistaId'],
      pedidoId: map['pedidoId'],
      vehiculoId: map['vehiculoId'],
      rutaId: map['rutaId'],
      companyId: map['companyId'],
      clienteId: map['clienteId'],
      fechaCreacion: map['fechaCreacion'] != null
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origen': origen,
      'destino': destino,
      'mercancia': mercancia,
      'numBultos': numBultos,
      'peso': peso,
      'largo': largo,
      'ancho': ancho,
      'alto': alto,
      'estado': estado,
      'fechaCarga': Timestamp.fromDate(fechaCarga),
      'fechaDescarga': Timestamp.fromDate(fechaDescarga),
      if (transportistaId != null) 'transportistaId': transportistaId,
      if (pedidoId != null) 'pedidoId': pedidoId,
      if (vehiculoId != null) 'vehiculoId': vehiculoId,
      if (rutaId != null) 'rutaId': rutaId,
      if (companyId != null) 'companyId': companyId,
      if (clienteId != null) 'clienteId': clienteId,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }
}
