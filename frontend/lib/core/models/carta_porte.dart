class CartaPorteSnapshotModel {
  final String clienteNombre;
  final String clienteNif;
  final String clienteDireccion;
  final String? clienteTelefono;
  final String? destinatarioNombre;
  final String? destinatarioNif;
  final String? destinatarioDireccion;
  final String? subcontratadoNombre;
  final String? subcontratadoNif;
  final String? subcontratadoDireccion;
  final String? subcontratadoTelefono;
  final String? subcontratadoNumAutorizacion;
  final String? subVehiculoMatricula;
  final String? subRemolqueMatricula;
  final double? precioNeto;
  final DateTime? congeladoAt;

  const CartaPorteSnapshotModel({
    required this.clienteNombre,
    required this.clienteNif,
    required this.clienteDireccion,
    this.clienteTelefono,
    this.destinatarioNombre,
    this.destinatarioNif,
    this.destinatarioDireccion,
    this.subcontratadoNombre,
    this.subcontratadoNif,
    this.subcontratadoDireccion,
    this.subcontratadoTelefono,
    this.subcontratadoNumAutorizacion,
    this.subVehiculoMatricula,
    this.subRemolqueMatricula,
    this.precioNeto,
    this.congeladoAt,
  });

  factory CartaPorteSnapshotModel.fromMap(Map<String, dynamic> map) {
    return CartaPorteSnapshotModel(
      clienteNombre: map['clienteNombre'] as String,
      clienteNif: map['clienteNif'] as String,
      clienteDireccion: map['clienteDireccion'] as String,
      clienteTelefono: map['clienteTelefono'] as String?,
      destinatarioNombre: map['destinatarioNombre'] as String?,
      destinatarioNif: map['destinatarioNif'] as String?,
      destinatarioDireccion: map['destinatarioDireccion'] as String?,
      subcontratadoNombre: map['subcontratadoNombre'] as String?,
      subcontratadoNif: map['subcontratadoNif'] as String?,
      subcontratadoDireccion: map['subcontratadoDireccion'] as String?,
      subcontratadoTelefono: map['subcontratadoTelefono'] as String?,
      subcontratadoNumAutorizacion: map['subcontratadoNumAutorizacion'] as String?,
      subVehiculoMatricula: map['subVehiculoMatricula'] as String?,
      subRemolqueMatricula: map['subRemolqueMatricula'] as String?,
      precioNeto: (map['precioNeto'] as num?)?.toDouble(),
      congeladoAt: map['congeladoAt'] != null
          ? DateTime.parse(map['congeladoAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteNombre': clienteNombre,
      'clienteNif': clienteNif,
      'clienteDireccion': clienteDireccion,
      if (clienteTelefono != null) 'clienteTelefono': clienteTelefono,
      if (destinatarioNombre != null) 'destinatarioNombre': destinatarioNombre,
      if (destinatarioNif != null) 'destinatarioNif': destinatarioNif,
      if (destinatarioDireccion != null) 'destinatarioDireccion': destinatarioDireccion,
      if (subcontratadoNombre != null) 'subcontratadoNombre': subcontratadoNombre,
      if (subcontratadoNif != null) 'subcontratadoNif': subcontratadoNif,
      if (subcontratadoDireccion != null) 'subcontratadoDireccion': subcontratadoDireccion,
      if (subcontratadoTelefono != null) 'subcontratadoTelefono': subcontratadoTelefono,
      if (subcontratadoNumAutorizacion != null) 'subcontratadoNumAutorizacion': subcontratadoNumAutorizacion,
      if (subVehiculoMatricula != null) 'subVehiculoMatricula': subVehiculoMatricula,
      if (subRemolqueMatricula != null) 'subRemolqueMatricula': subRemolqueMatricula,
      if (precioNeto != null) 'precioNeto': precioNeto,
      if (congeladoAt != null) 'congeladoAt': congeladoAt!.toIso8601String(),
    };
  }
}