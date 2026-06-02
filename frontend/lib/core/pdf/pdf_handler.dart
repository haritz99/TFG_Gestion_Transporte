import 'pdf_handler_stub.dart'
  if (dart.library.js_interop) 'pdf_handler_web.dart'
  if (dart.library.io) 'pdf_handler_mobile.dart';

abstract class PdfHandler {
  static PdfHandler instance = getPdfHandler();

  Future<void> open(String url, String filename);
}