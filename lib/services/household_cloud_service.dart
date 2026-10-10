import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haven_os/models/household.dart';

/// Cloud side of household join. Local HouseholdService stays for offline;
/// this makes invite codes work across two phones.
class HouseholdCloudService {
  HouseholdCloudService._();
  static final HouseholdCloudService instance = HouseholdCloudService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');

  CollectionReference<Map<String, dynamic>> get _inviteIndex =>
      _db.collection('household_invites');

  /// Writes household to Firestore and indexes invite code -> household id.
  Future<void> publishHousehold(Household household) async {
    if (household.id.isEmpty) {
      throw Exception('Household id required');
    }
    final data = household.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _households.doc(household.id).set(data, SetOptions(merge: true));

    final code = household.inviteCode.trim().toUpperCase();
    if (code.isNotEmpty) {
      await _inviteIndex.doc(code).set({
        'householdId': household.id,
        'inviteCode': code,
        'name': household.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Looks up a household by invite code (e.g. HAVEN-AB12) from the cloud.
  Future<Household?> findByInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final indexSnap = await _inviteIndex.doc(normalized).get();
    if (!indexSnap.exists) return null;

    final householdId = indexSnap.data()?['householdId'] as String?;
    if (householdId == null || householdId.isEmpty) return null;

    final hhSnap = await _households.doc(householdId).get();
    if (!hhSnap.exists || hhSnap.data() == null) return null;

    return Household.fromJson(hhSnap.data()!);
  }

  /// Adds [userId] to the household member list in the cloud.
  Future<Household> addMember({
    required String householdId,
    required String userId,
  }) async {
    final ref = _households.doc(householdId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Household not found in cloud');
    }

    final household = Household.fromJson(snap.data()!);
    final members = List<String>.from(household.memberIds);
    if (!members.contains(userId)) {
      members.add(userId);
    }

    final updated = household.copyWith(memberIds: members);
    await ref.set(updated.toJson(), SetOptions(merge: true));
    return updated;
  }

  /// Full cloud join: resolve code, add member, return household.
  Future<Household> joinByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final household = await findByInviteCode(inviteCode);
    if (household == null) {
      throw Exception('Invalid invite code');
    }
    return addMember(householdId: household.id, userId: userId);
  }
}
