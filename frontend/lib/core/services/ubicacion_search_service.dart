import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/direccion_model.dart';

Future<List<SugerenciaDireccion>> buscarDirecciones(String query) async {
  // Esto es el serivcio para pasar de direccion a lat/lng, se usa en crear tipo carga
  final texto = query.trim();
  if (texto.length < 3) return [];

  final uri = Uri.https('photon.komoot.io', '/api/', {
    'q': texto,
    'limit': '5',
    'lang': 'es',
  });

  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? [];

    return features.map((f) {
      final props = (f as Map<String, dynamic>)['properties'] as Map<String, dynamic>;
      final coords = (f['geometry'] as Map<String, dynamic>)['coordinates'] as List<dynamic>;

      final calleBase = (props['street'] as String?) ?? (props['name'] as String?) ?? '';
      final numero = props['housenumber'] as String?;
      final calle = numero != null && calleBase.isNotEmpty ? '$calleBase $numero' : calleBase;

      final direccion = DireccionModel(
        calle: calle,
        ciudad: (props['city'] as String?) ?? (props['town'] as String?) ?? (props['village'] as String?) ?? '',
        provincia: (props['state'] as String?) ?? (props['county'] as String?) ?? '',
        codigoPostal: (props['postcode'] as String?) ?? '',
        pais: (props['country'] as String?) ?? 'España',
      );

      final etiqueta = [direccion.calle, direccion.ciudad, direccion.provincia, direccion.pais]
          .where((p) => p.isNotEmpty)
          .join(', ');

      return SugerenciaDireccion(
        etiqueta: etiqueta,
        direccion: direccion,
        lat: (coords[1] as num).toDouble(),
        lng: (coords[0] as num).toDouble(),
      );
    }).toList();
  } catch (_) {
    return [];
  }
}