import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/auth/auth_provider.dart';
import 'package:gestion_transporte/core/services/voice_service.dart';
import 'package:gestion_transporte/core/services/api_service.dart';
import 'package:gestion_transporte/pages/login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voiceService = VoiceService();
  final ApiService _apiService = ApiService();
  String _lastCommand = '';
  String _response = '';
  bool _isListening = false;

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: (text) async {
          setState(() {
            _lastCommand = text;
            _isListening = false;
          });
          await _processVoiceCommand(text);
        },
      );
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    final authProvider = context.read<AuthProvider>();
    final idToken = await authProvider.getValidIdToken();
    if (idToken == null) {
      setState(() {
        _response = 'Sesion no valida. Inicia sesion de nuevo.';
      });
      return;
    }

    try {
      final result = await _apiService.detectIntent(text, idToken);
      setState(() {
        _response = result['response'] ?? 'Sin respuesta';
      });
    } catch (e) {
      setState(() {
        _response = 'Error al procesar comando: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.nombre ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 48,
                      color: _isListening ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isListening ? 'Escuchando...' : 'Pulsa para hablar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_lastCommand.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comando:', style: Theme.of(context).textTheme.labelLarge),
                      Text(_lastCommand),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_response.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Respuesta:', style: Theme.of(context).textTheme.labelLarge),
                      Text(_response),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}
