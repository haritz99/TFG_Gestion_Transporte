class PedidoModel {
  final String? id;
  final String? descripcion;
  final DateTime fechaCarga;
  final DateTime fechaDescarga;
  final List<String> origenes;
  final List<String> destinos;
  final EstadoPedido estado;
  final String clienteId;
  final String? companyId;
  final DateTime? createdAt;

  const PedidoModel({
    this.id,
    this.descripcion,
    required this.fechaCarga,
    required this.fechaDescarga,
    required this.origenes,
    required this.destinos,
    required this.estado,
    required this.clienteId,
    this.companyId,
    this.createdAt,
  });

  factory PedidoModel.fromMap(Map<String, dynamic> map, String id) {
    return PedidoModel(
      id: id,
      descripcion: map['descripcion'] as String?,
      fechaCarga: DateTime.parse(map['fechaCarga'] as String),
      fechaDescarga: DateTime.parse(map['fechaDescarga'] as String),
      origenes: List<String>.from(map['origenes'] as List),
      destinos: List<String>.from(map['destinos'] as List),
      estado: EstadoPedido.fromString(map['estado'] as String),
      clienteId: map['clienteId'] as String,
      companyId: map['companyId'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'fechaCarga': fechaCarga.toUtc().toIso8601String(),
      'fechaDescarga': fechaDescarga.toUtc().toIso8601String(),
      'origenes': origenes,
      'destinos': destinos,
      'estado': estado.name,
      'clienteId': clienteId,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  PedidoModel copyWith({
    String? id,
    String? descripcion,
    DateTime? fechaCarga,
    DateTime? fechaDescarga,
    List<String>? origenes,
    List<String>? destinos,
    EstadoPedido? estado,
    String? clienteId,
    String? companyId,
    DateTime? createdAt,
  }) {
    return PedidoModel(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      fechaDescarga: fechaDescarga ?? this.fechaDescarga,
      origenes: origenes ?? this.origenes,
      destinos: destinos ?? this.destinos,
      estado: estado ?? this.estado,
      clienteId: clienteId ?? this.clienteId,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum EstadoPedido {
  planificado,
  enCurso,
  completado,
  cancelado;

  static EstadoPedido fromString(String value) {
    return EstadoPedido.values.firstWhere(
          (e) => e.name == value,
      orElse: () => throw ArgumentError('EstadoPedido desconocido: $value'),
    );
  }
}