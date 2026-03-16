import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'es_ES',
  }) async {
    if (!_isInitialized) {
      final available = await initialize();
      if (!available) return;
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
