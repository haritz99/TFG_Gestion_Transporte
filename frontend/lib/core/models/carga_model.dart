import 'carta_porte.dart';

abstract class CargaBaseModel {
  final String origen;
  final String destino;
  final String mercancia;
  final int numBultos;
  final double peso;
  final double precio;
  final double? largo;
  final double? ancho;
  final double? alto;

  const CargaBaseModel({
    required this.origen,
    required this.destino,
    required this.mercancia,
    required this.numBultos,
    required this.peso,
    required this.precio,
    this.largo,
    this.ancho,
    this.alto,
  });
}

enum EstadoCarga {
  pendiente('pendiente'),
  asignado('asignado'),
  enTransito('en_transito'),
  entregado('entregado'),
  cedido('cedido');

  final String value;
  const EstadoCarga(this.value);

  static EstadoCarga fromString(String value) {
    return EstadoCarga.values.firstWhere(
          (e) => e.value == value,
      orElse: () => throw ArgumentError('EstadoCarga desconocido: $value'),
    );
  }
}

class TipoCargaModel extends CargaBaseModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final double pesoMax;
  final String companyId;

  const TipoCargaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.pesoMax,
    required this.companyId,
    required super.origen,
    required super.destino,
    required super.mercancia,
    required super.numBultos,
    required super.peso,
    required super.precio,
    super.largo,
    super.ancho,
    super.alto,
  });

  factory TipoCargaModel.fromMap(Map<String, dynamic> map, String id) {
    return TipoCargaModel(
      id: id,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      pesoMax: (map['pesoMax'] as num).toDouble(),
      companyId: map['companyId'] as String,
      origen: map['origen'] as String,
      destino: map['destino'] as String,
      mercancia: map['mercancia'] as String,
      numBultos: map['numBultos'] as int,
      peso: (map['peso'] as num).toDouble(),
      precio: (map['precio'] as num).toDouble(),
      largo: (map['largo'] as num?)?.toDouble(),
      ancho: (map['ancho'] as num?)?.toDouble(),
      alto: (map['alto'] as num?)?.toDouble(),
    );
  }
}

class CargaModel extends CargaBaseModel {
  final String? id;
  final EstadoCarga estado;
  final DateTime fechaCarga;
  final DateTime fechaDescarga;
  final String? transportistaId;
  final String? transportistaNombre;
  final String? pedidoId;
  final String? vehiculoId;
  final String? subVehiculoMatricula;
  final String? subRemolqueMatricula;
  final double? comisionCesion;
  final String? companyId;
  final String? clienteId;
  final CartaPorteSnapshotModel? cartaPorteSnapshot;

  const CargaModel({
    this.id,
    required this.estado,
    required this.fechaCarga,
    required this.fechaDescarga,
    this.transportistaId,
    this.transportistaNombre,
    this.pedidoId,
    this.vehiculoId,
    this.subVehiculoMatricula,
    this.subRemolqueMatricula,
    this.comisionCesion,
    this.companyId,
    this.clienteId,
    this.cartaPorteSnapshot,
    required super.origen,
    required super.destino,
    required super.mercancia,
    required super.numBultos,
    required super.peso,
    required super.precio,
    super.largo,
    super.ancho,
    super.alto,
  });

  factory CargaModel.fromTipoCarga(
      TipoCargaModel tipo, {
        required DateTime fechaCarga,
        required DateTime fechaDescarga,
        required String clienteId,
        required String companyId,
        String? transportistaId,
        String? vehiculoId,
        double? comisionCesion,
        String? pedidoId,
      }) {
    return CargaModel(
      origen: tipo.origen,
      destino: tipo.destino,
      mercancia: tipo.mercancia,
      numBultos: tipo.numBultos,
      peso: tipo.peso,
      precio: tipo.precio,
      largo: tipo.largo,
      ancho: tipo.ancho,
      alto: tipo.alto,
      fechaCarga: fechaCarga,
      fechaDescarga: fechaDescarga,
      clienteId: clienteId,
      companyId: companyId,
      transportistaId: transportistaId,
      vehiculoId: vehiculoId,
      comisionCesion: comisionCesion,
      pedidoId: pedidoId,
      estado: (transportistaId != null && vehiculoId != null)
          ? EstadoCarga.asignado
          : EstadoCarga.pendiente,
    );
  }

  factory CargaModel.fromMap(Map<String, dynamic> map, String id) {
    return CargaModel(
      id: id,
      origen: map['origen'] as String,
      destino: map['destino'] as String,
      mercancia: map['mercancia'] as String,
      numBultos: map['numBultos'] as int,
      peso: (map['peso'] as num).toDouble(),
      precio: (map['precio'] as num).toDouble(),
      largo: (map['largo'] as num?)?.toDouble(),
      ancho: (map['ancho'] as num?)?.toDouble(),
      alto: (map['alto'] as num?)?.toDouble(),
      estado: EstadoCarga.fromString(map['estado'] as String),
      fechaCarga: DateTime.parse(map['fechaCarga'] as String),
      fechaDescarga: DateTime.parse(map['fechaDescarga'] as String),
      transportistaId: map['transportistaId'] as String?,
      pedidoId: map['pedidoId'] as String?,
      vehiculoId: map['vehiculoId'] as String?,
      subVehiculoMatricula: map['subVehiculoMatricula'] as String?,
      subRemolqueMatricula: map['subRemolqueMatricula'] as String?,
      comisionCesion: (map['comisionCesion'] as num?)?.toDouble(),
      transportistaNombre: map['conductorNombre'] as String? ?? map['transportistaNombre'] as String?,
      companyId: map['companyId'] as String?,
      clienteId: map['clienteId'] as String?,
      cartaPorteSnapshot: map['cartaPorteSnapshot'] != null
          ? CartaPorteSnapshotModel.fromMap(
              Map<String, dynamic>.from(map['cartaPorteSnapshot'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'origen': origen,
      'destino': destino,
      'mercancia': mercancia,
      'numBultos': numBultos,
      'peso': peso,
      'precio': precio,
      if (largo != null) 'largo': largo,
      if (ancho != null) 'ancho': ancho,
      if (alto != null) 'alto': alto,
      'estado': estado.value,
      'fechaCarga': fechaCarga.toIso8601String(),
      'fechaDescarga': fechaDescarga.toIso8601String(),
      'transportistaId': transportistaId,
      'conductorNombre': transportistaNombre,
      if (pedidoId != null) 'pedidoId': pedidoId,
      'vehiculoId': vehiculoId,
      'subVehiculoMatricula': subVehiculoMatricula,
      'subRemolqueMatricula': subRemolqueMatricula,
      if (comisionCesion != null) 'comisionCesion': comisionCesion,
      if (companyId != null) 'companyId': companyId,
      if (clienteId != null) 'clienteId': clienteId,
      if (cartaPorteSnapshot != null)
        'cartaPorteSnapshot': cartaPorteSnapshot!.toMap(),
    };
  }

  CargaModel copyWith({
    String? id,
    EstadoCarga? estado,
    DateTime? fechaCarga,
    DateTime? fechaDescarga,
    String? transportistaId,
    bool clearTransportistaId = false,
    String? transportistaNombre,
    bool clearTransportistaNombre = false,
    String? pedidoId,
    String? vehiculoId,
    bool clearVehiculoId = false,
    String? subVehiculoMatricula,
    String? subRemolqueMatricula,
    double? comisionCesion,
    String? companyId,
    String? clienteId,
    String? origen,
    String? destino,
    String? mercancia,
    int? numBultos,
    double? peso,
    double? precio,
    double? largo,
    double? ancho,
    double? alto,
    CartaPorteSnapshotModel? cartaPorteSnapshot,
  }) {
    return CargaModel(
      id: id ?? this.id,
      estado: estado ?? this.estado,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      fechaDescarga: fechaDescarga ?? this.fechaDescarga,
      transportistaId: clearTransportistaId ? null : (transportistaId ?? this.transportistaId),
      transportistaNombre: clearTransportistaNombre ? null : (transportistaNombre ?? this.transportistaNombre),
      pedidoId: pedidoId ?? this.pedidoId,
      vehiculoId: clearVehiculoId ? null : (vehiculoId ?? this.vehiculoId),
      subVehiculoMatricula: subVehiculoMatricula ?? this.subVehiculoMatricula,
      subRemolqueMatricula: subRemolqueMatricula ?? this.subRemolqueMatricula,
      comisionCesion: comisionCesion ?? this.comisionCesion,
      companyId: companyId ?? this.companyId,
      clienteId: clienteId ?? this.clienteId,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      mercancia: mercancia ?? this.mercancia,
      numBultos: numBultos ?? this.numBultos,
      peso: peso ?? this.peso,
      precio: precio ?? this.precio,
      largo: largo ?? this.largo,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      cartaPorteSnapshot: cartaPorteSnapshot ?? this.cartaPorteSnapshot,
    );
  }
}
