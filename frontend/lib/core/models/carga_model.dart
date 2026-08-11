import 'dart:ui';
import '../theme/app_colors.dart';
import 'carta_porte.dart';
import 'direccion_model.dart';
import 'model_utils.dart';

enum TipoCarga {
  bultos('bultos'),
  granel('granel'),
  liquido('liquido');

  final String value;
  const TipoCarga(this.value);

  static TipoCarga fromString(String value) {
    return TipoCarga.values.firstWhere((e) => e.value == value,
      orElse: () => throw ArgumentError('TipoCarga desconocido: $value'),
    );
  }
}

abstract class CargaBaseModel {
  final TipoCarga tipoCarga;
  final UbicacionModel origen;
  final UbicacionModel destino;
  final String mercancia;
  final String? tipoEmbalaje;
  final int? numBultos;
  final double? peso;
  final double precio;
  final bool apilable;
  final double? volumen;
  final double? longitudLineal;
  final double? largo;
  final double? ancho;
  final double? alto;

  const CargaBaseModel({
    required this.origen,
    required this.destino,
    required this.mercancia,
    this.tipoEmbalaje,
    this.tipoCarga = TipoCarga.bultos,
    this.numBultos,
    this.peso,
    required this.precio,
    this.apilable = false,
    this.volumen,
    this.longitudLineal,
    this.largo,
    this.ancho,
    this.alto,
  });

  String get origenTexto => origen.direccionTexto;
  String get destinoTexto => destino.direccionTexto;
}

enum EstadoCarga {
  pendiente('pendiente'),
  planificado('planificado'),
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
  final double? pesoMax;
  final String companyId;
  final String clienteId;

  const TipoCargaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.pesoMax,
    required this.companyId,
    required this.clienteId,
    required super.origen,
    required super.destino,
    required super.mercancia,
    super.tipoEmbalaje,
    super.tipoCarga,
    super.numBultos,
    super.peso,
    required super.precio,
    super.apilable,
    super.volumen,
    super.longitudLineal,
    super.largo,
    super.ancho,
    super.alto,
  });

  factory TipoCargaModel.fromMap(Map<String, dynamic> map, String id) {
    return TipoCargaModel(
      id: id,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      pesoMax: (map['pesoMax'] as num?)?.toDouble(),
      companyId: map['companyId'] as String,
      clienteId: map['clienteId'] as String,
      tipoCarga: map['tipoCarga'] != null
          ? TipoCarga.fromString(map['tipoCarga'] as String)
          : TipoCarga.bultos,
      origen: UbicacionModel.fromMap(map['origen'] as Map<String, dynamic>),
      destino: UbicacionModel.fromMap(map['destino'] as Map<String, dynamic>),
      mercancia: map['mercancia'] as String,
      tipoEmbalaje: map['tipoEmbalaje'] as String?,
      numBultos: map['numBultos'] as int?,
      peso: (map['peso'] as num?)?.toDouble(),
      precio: (map['precio'] as num).toDouble(),
      apilable: map['apilable'] as bool? ?? false,
      volumen: (map['volumen'] as num?)?.toDouble(),
      longitudLineal: (map['longitudLineal'] as num?)?.toDouble(),
      largo: (map['largo'] as num?)?.toDouble(),
      ancho: (map['ancho'] as num?)?.toDouble(),
      alto: (map['alto'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (pesoMax != null) 'pesoMax': pesoMax,
      'companyId': companyId,
      'clienteId': clienteId,
      'tipoCarga': tipoCarga.value,
      'origen': origen.toMap(),
      'destino': destino.toMap(),
      'mercancia': mercancia,
      if (tipoEmbalaje != null) 'tipoEmbalaje': tipoEmbalaje,
      if (numBultos != null) 'numBultos': numBultos,
      if (peso != null) 'peso': peso,
      'precio': precio,
      'apilable': apilable,
      if (volumen != null) 'volumen': volumen,
      if (longitudLineal != null) 'longitudLineal': longitudLineal,
      if (largo != null) 'largo': largo,
      if (ancho != null) 'ancho': ancho,
      if (alto != null) 'alto': alto,
    };
  }
}

class CargaModel extends CargaBaseModel {
  final String? id;
  final EstadoCarga estado;
  final DateTime fechaCarga;
  final int? bufferHours;
  final DateTime fechaDescarga;
  final String? transportistaId;
  final String? transportistaNombre;
  final String? pedidoId;
  final String? vehiculoId;
  final double? comisionCesion;
  final String? companyId;
  final String? clienteId;
  final CartaPorteSnapshotModel? cartaPorteSnapshot;
  final String? cartaPorteUrl;

  const CargaModel({
    this.id,
    required this.estado,
    required this.fechaCarga,
    required this.fechaDescarga,
    this.bufferHours,
    this.transportistaId,
    this.transportistaNombre,
    this.pedidoId,
    this.vehiculoId,
    this.comisionCesion,
    this.companyId,
    this.clienteId,
    this.cartaPorteUrl,
    this.cartaPorteSnapshot,
    required super.origen,
    required super.destino,
    required super.mercancia,
    super.tipoEmbalaje,
    super.tipoCarga,
    super.numBultos,
    super.peso,
    required super.precio,
    super.apilable,
    super.volumen,
    super.longitudLineal,
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
        int? bufferHours,
        String? transportistaId,
        String? vehiculoId,
        double? comisionCesion,
        String? pedidoId,
      }) {
    return CargaModel(
      tipoCarga: tipo.tipoCarga,
      origen: tipo.origen,
      destino: tipo.destino,
      mercancia: tipo.mercancia,
      tipoEmbalaje: tipo.tipoEmbalaje,
      numBultos: tipo.numBultos,
      peso: tipo.peso,
      precio: tipo.precio,
      apilable: tipo.apilable,
      volumen: tipo.volumen,
      longitudLineal: tipo.longitudLineal,
      largo: tipo.largo,
      ancho: tipo.ancho,
      alto: tipo.alto,
      fechaCarga: fechaCarga,
      fechaDescarga: fechaDescarga,
      bufferHours: bufferHours,
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
      tipoCarga: map['tipoCarga'] != null
          ? TipoCarga.fromString(map['tipoCarga'] as String)
          : TipoCarga.bultos,
      origen: UbicacionModel.fromMap(map['origen'] as Map<String, dynamic>),
      destino: UbicacionModel.fromMap(map['destino'] as Map<String, dynamic>),
      mercancia: map['mercancia'] as String,
      tipoEmbalaje: map['tipoEmbalaje'] as String?,
      numBultos: map['numBultos'] as int?,
      peso: (map['peso'] as num?)?.toDouble(),
      precio: (map['precio'] as num).toDouble(),
      apilable: map['apilable'] as bool? ?? false,
      volumen: (map['volumen'] as num?)?.toDouble(),
      longitudLineal: (map['longitudLineal'] as num?)?.toDouble(),
      largo: (map['largo'] as num?)?.toDouble(),
      ancho: (map['ancho'] as num?)?.toDouble(),
      alto: (map['alto'] as num?)?.toDouble(),
      estado: EstadoCarga.fromString(map['estado'] as String),
      fechaCarga: ModelUtils.parseDateTime(map['fechaCarga']) ?? DateTime.now(),
      fechaDescarga: ModelUtils.parseDateTime(map['fechaDescarga']) ?? DateTime.now(),
      bufferHours: map['bufferHours'] as int?,
      transportistaId: map['transportistaId'] as String?,
      pedidoId: map['pedidoId'] as String?,
      vehiculoId: map['vehiculoId'] as String?,
      comisionCesion: (map['comisionCesion'] as num?)?.toDouble(),
      transportistaNombre: map['conductorNombre'] as String? ?? map['transportistaNombre'] as String?,
      companyId: map['companyId'] as String?,
      clienteId: map['clienteId'] as String?,
      cartaPorteUrl: map['carta_porte_url'] as String?,
      cartaPorteSnapshot: map['cartaPorteSnapshot'] != null ? CartaPorteSnapshotModel.fromMap(
          Map<String, dynamic>.from(map['cartaPorteSnapshot'] as Map)) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipoCarga': tipoCarga.value,
      'origen': origen.toMap(),
      'destino': destino.toMap(),
      'mercancia': mercancia,
      if (tipoEmbalaje != null) 'tipoEmbalaje': tipoEmbalaje,
      if (numBultos != null) 'numBultos': numBultos,
      if (peso != null) 'peso': peso,
      'precio': precio,
      'apilable': apilable,
      if (volumen != null) 'volumen': volumen,
      if (longitudLineal != null) 'longitudLineal': longitudLineal,
      if (largo != null) 'largo': largo,
      if (ancho != null) 'ancho': ancho,
      if (alto != null) 'alto': alto,
      'estado': estado.value,
      'fechaCarga': fechaCarga.toIso8601String(),
      'fechaDescarga': fechaDescarga.toIso8601String(),
      if (bufferHours != null) 'bufferHours': bufferHours,
      'transportistaId': transportistaId,
      'conductorNombre': transportistaNombre,
      if (pedidoId != null) 'pedidoId': pedidoId,
      'vehiculoId': vehiculoId,
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
    int? bufferHours,
    bool clearBufferHours = false,
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
    TipoCarga? tipoCarga,
    UbicacionModel? origen,
    UbicacionModel? destino,
    String? mercancia,
    String? tipoEmbalaje,
    int? numBultos,
    double? peso,
    double? precio,
    bool? apilable,
    double? volumen,
    double? longitudLineal,
    double? largo,
    double? ancho,
    double? alto,
    CartaPorteSnapshotModel? cartaPorteSnapshot,
    String? cartaPorteUrl,
  }) {
    return CargaModel(
      id: id ?? this.id,
      estado: estado ?? this.estado,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      fechaDescarga: fechaDescarga ?? this.fechaDescarga,
      bufferHours: clearBufferHours ? null : (bufferHours ?? this.bufferHours),
      transportistaId: clearTransportistaId ? null : (transportistaId ?? this.transportistaId),
      transportistaNombre: clearTransportistaNombre ? null : (transportistaNombre ?? this.transportistaNombre),
      pedidoId: pedidoId ?? this.pedidoId,
      vehiculoId: clearVehiculoId ? null : (vehiculoId ?? this.vehiculoId),
      comisionCesion: comisionCesion ?? this.comisionCesion,
      companyId: companyId ?? this.companyId,
      clienteId: clienteId ?? this.clienteId,
      tipoCarga: tipoCarga ?? this.tipoCarga,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      mercancia: mercancia ?? this.mercancia,
      tipoEmbalaje: tipoEmbalaje ?? this.tipoEmbalaje,
      numBultos: numBultos ?? this.numBultos,
      peso: peso ?? this.peso,
      precio: precio ?? this.precio,
      apilable: apilable ?? this.apilable,
      volumen: volumen ?? this.volumen,
      longitudLineal: longitudLineal ?? this.longitudLineal,
      largo: largo ?? this.largo,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      cartaPorteSnapshot: cartaPorteSnapshot ?? this.cartaPorteSnapshot,
      cartaPorteUrl: cartaPorteUrl ?? this.cartaPorteUrl,
    );
  }

  static Color getColorByEstado(String estado) {
    if (estado == EstadoCarga.entregado.value) return AppColors.calendarEntregado;
    if (estado == EstadoCarga.planificado.value) return AppColors.calendarPlanificado;
    if (estado == EstadoCarga.asignado.value) return AppColors.calendarAsignado;
    if (estado == EstadoCarga.enTransito.value) return AppColors.calendarEnRuta;
    return AppColors.calendarPendiente;
  }
}
