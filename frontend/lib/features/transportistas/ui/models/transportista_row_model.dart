class TransportistaRowModel {
  const TransportistaRowModel({
    this.uid = '', // No lo enseño en la tabla pero es neceario para los callbacks
    this.nombre = '',
    this.apellido = '',
    this.email = '',
    this.telefono = '',
    this.rol = const [],
    this.licencias = const [],
    this.cargaAsignada = '',
    this.fechaDeAlta = '',
    this.vehiculoAsignado = '',
    this.estado = 'disponible'
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final List<String> rol;
  final List<String> licencias;
  final String cargaAsignada;
  final String fechaDeAlta;
  final String vehiculoAsignado;
  final String estado;

}