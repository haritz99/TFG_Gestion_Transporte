import 'package:flutter/material.dart';

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

  factory DireccionModel.fromMap(Map<String, dynamic> map) {
    return DireccionModel(
      calle: map['calle'] as String,
      ciudad: map['ciudad'] as String,
      provincia: map['provincia'] as String,
      codigoPostal: map['codigoPostal'] as String,
      pais: map['pais'] as String? ?? 'España',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calle': calle,
      'ciudad': ciudad,
      'provincia': provincia,
      'codigoPostal': codigoPostal,
      'pais': pais,
    };
  }

  String get textoDireccion => '$calle, $codigoPostal $ciudad ($provincia), $pais';
}


class UbicacionModel {
  final DireccionModel direccion;
  final double lat;
  final double lng;

  const UbicacionModel({
    required this.direccion,
    required this.lat,
    required this.lng,
  });

  factory UbicacionModel.fromMap(Map<String, dynamic> map) {
    return UbicacionModel(
      direccion: DireccionModel.fromMap(map['direccion'] as Map<String, dynamic>),
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'direccion': direccion.toMap(),
      'lat': lat,
      'lng': lng,
    };
  }

  String get direccionTexto => direccion.textoDireccion;
  Uri get googleMapsUri => Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
}


// Esto es para tipo carga (direccion -> lat/lng)
class SugerenciaDireccion {
  final String etiqueta;
  final DireccionModel direccion;
  final double lat;
  final double lng;

  SugerenciaDireccion({
    required this.etiqueta,
    required this.direccion,
    required this.lat,
    required this.lng,
  });
}

class UbicacionControllers {
  final calle = TextEditingController();
  final ciudad = TextEditingController();
  final provincia = TextEditingController();
  final codigoPostal = TextEditingController();
  final pais = TextEditingController(text: 'España');
  final lat = TextEditingController();
  final lng = TextEditingController();

  void dispose() {
    calle.dispose();
    ciudad.dispose();
    provincia.dispose();
    codigoPostal.dispose();
    pais.dispose();
    lat.dispose();
    lng.dispose();
  }

  void aplicarSugerencia(SugerenciaDireccion sugerencia) {
    calle.text = sugerencia.direccion.calle;
    ciudad.text = sugerencia.direccion.ciudad;
    provincia.text = sugerencia.direccion.provincia;
    codigoPostal.text = sugerencia.direccion.codigoPostal;
    pais.text = sugerencia.direccion.pais;
    lat.text = sugerencia.lat.toString();
    lng.text = sugerencia.lng.toString();
  }

  UbicacionModel toModel() {
    return UbicacionModel(
      direccion: DireccionModel(
        calle: calle.text.trim(),
        ciudad: ciudad.text.trim(),
        provincia: provincia.text.trim(),
        codigoPostal: codigoPostal.text.trim(),
        pais: pais.text.trim(),
      ),
      lat: double.parse(lat.text.replaceAll(',', '.')),
      lng: double.parse(lng.text.replaceAll(',', '.')),
    );
  }
}