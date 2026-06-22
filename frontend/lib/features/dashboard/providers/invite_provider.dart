import 'package:flutter/foundation.dart';
import '../../../core/models/external_user_model.dart';
import '../../auth/providers/token_provider.dart';
import '../data/invite_service.dart';

class InviteProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isCreated = false;
  List<ExternalUserModel> _guests = [];
  String? tempPassword;
  String? resetLink;
  final InviteService _service;
  String? _message;

  InviteProvider({
    required AuthTokenProvider tokenProvider,
    InviteService? service,
  }) : _service = service ?? InviteService(tokenProvider);

  String? get message => _message;
  List<ExternalUserModel> get guests => _guests;

  Future<void> createUser(String email, String rol) async {
    isLoading = true;
    notifyListeners();

    try {
      rol == 'cliente' ? await _service.createCliente(email) : await _service.createSubcontratado(email);
      isCreated = true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendInviteEmail(String email) async {
    isLoading = true;
    notifyListeners();
    try {
      _message = await _service.sendInviteEmail(email);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
        isLoading = false;
        notifyListeners();
        return false;
    }
  }


  Future<void> getGuests() async {
    isLoading = true;
    notifyListeners();
    try {
      if (_guests.isNotEmpty) return;
      _guests = await _service.fetchGuests();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGuest(String uid) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteGuest(uid);
      _guests.removeWhere((guest) => guest.uid == uid);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}