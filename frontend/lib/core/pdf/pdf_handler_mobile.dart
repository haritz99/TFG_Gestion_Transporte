import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'pdf_handler.dart';

class PdfHandlerMobile implements PdfHandler {
  @override
  Future<void> open(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();

        final safeFilename = filename.endsWith('.pdf') ? filename : '$filename.pdf';
        final file = File('${dir.path}/$safeFilename');

        await file.writeAsBytes(response.bodyBytes);

        await OpenFilex.open(file.path);
      } else {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al abrir el PDF: $e');
    }
  }

}
  PdfHandler getPdfHandler() => PdfHandlerMobile();
