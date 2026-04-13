class TransportistaRowModel {
  const TransportistaRowModel({
    this.nombre = '',
    this.apellido = '',
    this.email = '',
    this.telefono = '',
    this.rol = const [],
    this.licencias = const [],
    this.cargaAsignada = '',
    this.fechaDeAlta = '',
    this.vehiculoAsignado = ''
  });

  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final List<String> rol;
  final List<String> licencias;
  final String cargaAsignada;
  final String fechaDeAlta;
  final String vehiculoAsignado;

}