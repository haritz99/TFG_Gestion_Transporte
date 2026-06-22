import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/models/carga_model.dart';

class ConductorProvider extends ChangeNotifier {
  final String conductorId;
  final String companyId;

  List<CargaModel> _cargas = [];
  StreamSubscription? _subscription;
  bool isLoading = true;
  String? errorMessage;

  ConductorProvider({
    required this.conductorId,
    required this.companyId,
  }) {
    _startListening();
  }

  List<CargaModel> get cargas => _cargas;

  CargaModel? get proximaEntrega {
    final activas = _cargas.where((c) =>
    c.estado == EstadoCarga.asignado ||
        c.estado == EstadoCarga.enTransito
    ).toList()
      ..sort((a, b) => a.fechaDescarga.compareTo(b.fechaDescarga));
    return activas.isEmpty ? null : activas.first;
  }

  List<CargaModel> get cargasHoy {
    final hoy = DateTime.now();
    return _cargas.where((c) =>
    c.fechaCarga.year == hoy.year &&
        c.fechaCarga.month == hoy.month &&
        c.fechaCarga.day == hoy.day
    ).toList();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void _startListening() {
    _subscription = FirebaseFirestore.instance
        .collection('/cargas')
        .where('transportistaId', isEqualTo: conductorId)
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .listen(
          (snapshot) {
        _cargas = snapshot.docs
            .map((doc) => CargaModel.fromMap(doc.data(), doc.id))
            .toList();
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = 'Error al cargar las cargas';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}