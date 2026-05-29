class DireccionModel {
  final String calle;
  final String ciudad;
  final String provincia;
  final String codigoPostal;
  final String pais;

  const DireccionModel({
    required this.calle,
    required this.ciudad,
    required this.provincia,
    required this.codigoPostal,
    this.pais = 'España',
  });

  Map<String, dynamic> toMap() {
    return {
      'calle': calle,
      'ciudad': ciudad,
      'provincia': provincia,
      'codigoPostal': codigoPostal,
      'pais': pais,
    };
  }
}
