class TransportistaRowModel {
  TransportistaRowModel({
    this.uid = '', // No lo enseño en la tabla pero es neceario para los callbacks
    this.nombre = '',
    this.apellido = '',
    this.email = '',
    this.telefono = '',
    this.licencias = const [],
    this.cargaAsignada = '',
    this.vehiculoAsignado = '',
    this.estado = 'Sin Asignar',
    this.fechaDeAlta,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final List<String> licencias;
  final String cargaAsignada;
  final String vehiculoAsignado;
  final String estado;
  final DateTime? fechaDeAlta;
}