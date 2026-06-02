import 'package:web/web.dart' as web;
import 'pdf_handler.dart';

class PdfHandlerWeb implements PdfHandler {
  @override
  Future<void> open(String url, String filename) async {
    web.window.open(url, '_blank');
  }
}

PdfHandler getPdfHandler() => PdfHandlerWeb();

