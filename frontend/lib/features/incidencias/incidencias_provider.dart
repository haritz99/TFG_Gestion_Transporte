import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/models/incidencia_model.dart';
import '../auth/providers/token_provider.dart';
import 'incidencia_service.dart';

class IncidenciaProvider extends ChangeNotifier {
  final IncidenciaService _service;
  final String companyId;
  List<IncidenciaModel> _incidencias = [];
  StreamSubscription? _subscription;
  bool isLoading = true;
  String? errorMessage;


  IncidenciaProvider({required this.companyId, required AuthTokenProvider tokenProvider, IncidenciaService? service,
  }) : _service = service ?? IncidenciaService(tokenProvider) {
    _startListening();
  }

  List<IncidenciaModel> get incidencias => _incidencias;

  void _startListening() {
    if (companyId.isEmpty) return;
    _subscription = FirebaseFirestore.instance
        .collection('incidencias')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
        _incidencias = snapshot.docs.map((doc) => IncidenciaModel.fromMap(doc.data(), doc.id)).toList();
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = 'Error al cargar incidencias';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createIncidencia({required String cargaId, required TipoIncidencia tipo, required String descripcion,}) async {
    try {
      await _service.createIncidencia(cargaId: cargaId, tipo: tipo.name, descripcion: descripcion);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> resolverIncidencia({required String cargaId,required String incidenciaId,
  }) async {
    try {
      await _service.resolverIncidencia(
        cargaId: cargaId,
        incidenciaId: incidenciaId,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}