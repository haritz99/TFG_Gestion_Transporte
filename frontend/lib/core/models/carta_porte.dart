class CartaPorteSnapshotModel {
  final String clienteNombre;
  final String clienteNif;
  final String clienteDireccion;
  final String? clienteTelefono;
  final String? subcontratadoNombre;
  final String? subcontratadoNif;
  final String? subcontratadoDireccion;
  final String? subcontratadoTelefono;
  final String? subcontratadoNumAutorizacion;
  final DateTime? congeladoAt;

  const CartaPorteSnapshotModel({
    required this.clienteNombre,
    required this.clienteNif,
    required this.clienteDireccion,
    this.clienteTelefono,
    this.subcontratadoNombre,
    this.subcontratadoNif,
    this.subcontratadoDireccion,
    this.subcontratadoTelefono,
    this.subcontratadoNumAutorizacion,
    this.congeladoAt,
  });

  factory CartaPorteSnapshotModel.fromMap(Map<String, dynamic> map) {
    return CartaPorteSnapshotModel(
      clienteNombre: map['clienteNombre'] as String,
      clienteNif: map['clienteNif'] as String,
      clienteDireccion: map['clienteDireccion'] as String,
      clienteTelefono: map['clienteTelefono'] as String?,
      subcontratadoNombre: map['subcontratadoNombre'] as String?,
      subcontratadoNif: map['subcontratadoNif'] as String?,
      subcontratadoDireccion: map['subcontratadoDireccion'] as String?,
      subcontratadoTelefono: map['subcontratadoTelefono'] as String?,
      subcontratadoNumAutorizacion:
          map['subcontratadoNumAutorizacion'] as String?,
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
      if (subcontratadoNombre != null)
        'subcontratadoNombre': subcontratadoNombre,
      if (subcontratadoNif != null) 'subcontratadoNif': subcontratadoNif,
      if (subcontratadoDireccion != null)
        'subcontratadoDireccion': subcontratadoDireccion,
      if (subcontratadoTelefono != null)
        'subcontratadoTelefono': subcontratadoTelefono,
      if (subcontratadoNumAutorizacion != null)
        'subcontratadoNumAutorizacion': subcontratadoNumAutorizacion,
      if (congeladoAt != null)
        'congeladoAt': congeladoAt!.toIso8601String(),
    };
  }
}
