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
  pendiente,
  asignado,
  enTransito,
  entregado;

  static EstadoCarga fromString(String value) {
    return EstadoCarga.values.firstWhere(
          (e) => e.name == value,
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
  final String? pedidoId;
  final String? vehiculoId;
  final String? companyId;
  final String? clienteId;

  const CargaModel({
    this.id,
    required this.estado,
    required this.fechaCarga,
    required this.fechaDescarga,
    this.transportistaId,
    this.pedidoId,
    this.vehiculoId,
    this.companyId,
    this.clienteId,
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
      pedidoId: pedidoId,
      estado: (transportistaId != null || vehiculoId != null)
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
      companyId: map['companyId'] as String?,
      clienteId: map['clienteId'] as String?,
    );
  }
}
