import 'dart:convert';
import 'package:haven_os/models/household.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';

class HouseholdService {
  static const String _householdsKey = 'households';
  static const String _requestsKey = 'join_requests';

  // ---- Household CRUD ----

  static Future<void> saveHouseholds(List<Household> households) async {
    final json = households.map((h) => h.toJson()).toList();
    await AuthService.storage
        .write(key: _householdsKey, value: jsonEncode(json));
  }

  static Future<List<Household>> loadHouseholds() async {
    final data = await AuthService.storage.read(key: _householdsKey);
    if (data == null) return [];
    try {
      final json = jsonDecode(data) as List;
      return json.map((j) => Household.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> createHousehold(String name, String adminUserId) async {
    final households = await loadHouseholds();
    if (households.any((h) => h.name == name)) {
      throw Exception('A household with that name already exists.');
    }
    final newHousehold = Household(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    households.add(newHousehold);
    await saveHouseholds(households);

    final user = await AuthService.getUserById(adminUserId);
    if (user != null) {
      final updatedUser = UserAccount(
        id: user.id,
        householdId: newHousehold.id,
        name: user.name,
        type: user.type,
        role: user.role,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      );
      await AuthService.updateUser(updatedUser);
    }
  }

  static Future<Household?> getHouseholdByName(String name) async {
    final households = await loadHouseholds();
    try {
      return households.firstWhere((h) => h.name == name);
    } catch (_) {
      return null;
    }
  }

  // ---- Join Requests ----

  static Future<void> saveRequests(List<JoinRequest> requests) async {
    final json = requests.map((r) => r.toJson()).toList();
    await AuthService.storage.write(key: _requestsKey, value: jsonEncode(json));
  }

  static Future<List<JoinRequest>> loadRequests() async {
    final data = await AuthService.storage.read(key: _requestsKey);
    if (data == null) return [];
    try {
      final json = jsonDecode(data) as List;
      return json.map((j) => JoinRequest.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> createRequest({
    required String requesterUserId,
    required String requesterName,
    required String householdId,
    required String householdName,
    String? message,
  }) async {
    final requests = await loadRequests();
    final existing = requests.any((r) =>
        r.requesterUserId == requesterUserId &&
        r.householdId == householdId &&
        r.status == JoinRequestStatus.pending);
    if (existing) return;

    final request = JoinRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requesterUserId: requesterUserId,
      requesterName: requesterName,
      householdId: householdId,
      householdName: householdName,
      message: message,
    );
    requests.add(request);
    await saveRequests(requests);
  }

  static Future<void> approveRequest(
      String requestId, String adminUserId) async {
    final requests = await loadRequests();
    final index = requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    final request = requests[index];

    final admin = await AuthService.getUserById(adminUserId);
    if (admin == null || admin.role != UserRole.administrator) {
      throw Exception('Only an administrator can approve requests.');
    }

    // Create a new request with status approved
    final approvedRequest = JoinRequest(
      id: request.id,
      requesterUserId: request.requesterUserId,
      requesterName: request.requesterName,
      householdId: request.householdId,
      householdName: request.householdName,
      message: request.message,
      status: JoinRequestStatus.approved,
      createdAt: request.createdAt,
    );
    requests[index] = approvedRequest;

    // Update the requester's householdId
    final user = await AuthService.getUserById(request.requesterUserId);
    if (user != null) {
      final updatedUser = UserAccount(
        id: user.id,
        householdId: request.householdId,
        name: user.name,
        type: user.type,
        role: user.role,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      );
      await AuthService.updateUser(updatedUser);
    }
    await saveRequests(requests);
  }

  static Future<void> rejectRequest(String requestId) async {
    final requests = await loadRequests();
    requests.removeWhere((r) => r.id == requestId);
    await saveRequests(requests);
  }

  static Future<List<JoinRequest>> getPendingRequests(
      String householdId) async {
    final all = await loadRequests();
    return all
        .where((r) =>
            r.householdId == householdId &&
            r.status == JoinRequestStatus.pending)
        .toList();
  }
}
