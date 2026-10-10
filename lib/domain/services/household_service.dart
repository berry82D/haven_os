import 'dart:convert';
import 'dart:math';
import 'package:haven_os/models/household.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';

class HouseholdService {
  static const String _householdsKey = 'households';
  static const String _requestsKey = 'join_requests';

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final body = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return 'HAVEN-$body';
  }

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
      return json.map((j) => Household.fromJson(j as Map<String, dynamic>)).toList();
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
      id: 'hh_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      inviteCode: _generateInviteCode(),
      ownerUserId: adminUserId,
      memberIds: [adminUserId],
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

  /// Creates a household record and returns it.
  /// [ownerUserId] is optional at create-account time (may be empty until user id exists).
  static Future<Household> createHouseholdRecord(
    String name, {
    String ownerUserId = '',
  }) async {
    final households = await loadHouseholds();
    final cleaned = name.trim().isEmpty ? 'My Household' : name.trim();
    final newHousehold = Household(
      id: 'hh_${DateTime.now().millisecondsSinceEpoch}',
      name: cleaned,
      createdAt: DateTime.now(),
      inviteCode: _generateInviteCode(),
      ownerUserId: ownerUserId,
      memberIds: ownerUserId.isEmpty ? const [] : [ownerUserId],
    );
    households.add(newHousehold);
    await saveHouseholds(households);
    return newHousehold;
  }

  static Future<Household?> getHouseholdByName(String name) async {
    final households = await loadHouseholds();
    try {
      return households.firstWhere((h) => h.name == name);
    } catch (_) {
      return null;
    }
  }

  static Future<Household?> getHouseholdById(String id) async {
    final households = await loadHouseholds();
    try {
      return households.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Household?> getHouseholdByInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final households = await loadHouseholds();
    try {
      return households.firstWhere(
        (h) => h.inviteCode.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adds [userId] to the household matching [inviteCode] and sets their householdId.
  static Future<Household> joinByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final household = await getHouseholdByInviteCode(inviteCode);
    if (household == null) {
      throw Exception('Invalid invite code');
    }

    final members = List<String>.from(household.memberIds);
    if (!members.contains(userId)) {
      members.add(userId);
    }

    final updated = household.copyWith(memberIds: members);
    final all = await loadHouseholds();
    final index = all.indexWhere((h) => h.id == household.id);
    if (index == -1) {
      throw Exception('Household not found');
    }
    all[index] = updated;
    await saveHouseholds(all);

    final user = await AuthService.getUserById(userId);
    if (user != null) {
      await AuthService.updateUser(UserAccount(
        id: user.id,
        householdId: updated.id,
        name: user.name,
        type: user.type,
        role: user.role,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      ));
    }

    return updated;
  }

  // ---- Join Requests (legacy local flow; kept) ----

  static Future<void> saveRequests(List<JoinRequest> requests) async {
    final json = requests.map((r) => r.toJson()).toList();
    await AuthService.storage.write(key: _requestsKey, value: jsonEncode(json));
  }

  static Future<List<JoinRequest>> loadRequests() async {
    final data = await AuthService.storage.read(key: _requestsKey);
    if (data == null) return [];
    try {
      final json = jsonDecode(data) as List;
      return json.map((j) => JoinRequest.fromJson(j as Map<String, dynamic>)).toList();
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
    final already = requests.any((r) =>
        r.requesterUserId == requesterUserId &&
        r.householdId == householdId &&
        r.status == JoinRequestStatus.pending);
    if (already) return;

    final request = JoinRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requesterUserId: requesterUserId,
      requesterName: requesterName,
      householdId: householdId,
      householdName: householdName,
      message: message,
      status: JoinRequestStatus.pending,
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
