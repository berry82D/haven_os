import 'package:haven_os/models/user_account.dart';

// ============================================================
// PermissionService
// ------------------------------------------------------------
// Single source of truth for "can this account do X". Replaces
// scattered `isParentAccount` / `_currentUser!.isParent` checks
// with one real gate that AppState's mutating methods call.
//
// Design: each UserRole gets a sensible DEFAULT capability set.
// An individual account can override any single capability via
// UserAccount.permissions (a Map<String,bool> keyed by
// Capability.name) — that field already existed on UserAccount
// but was previously never read or written anywhere. This lets
// account creation show "role" as the primary choice, with
// capability toggles as optional fine-tuning rather than a
// blank checklist the user has to fully configure.
// ============================================================

enum Capability {
  manageHousehold, // create/rename household, approve/reject join requests
  manageAccounts, // create/delete accounts, promote another account to Parent
  manageFinances, // add/edit/delete transactions, bills, loans
  manageHomestead, // add/edit/delete animals, feed deliveries
  manageTasks, // add/edit/delete tasks
  viewHouseholdData, // view other household members' data, not just your own
}

class PermissionService {
  static const Map<UserRole, Set<Capability>> _defaults = {
    UserRole.administrator: {
      Capability.manageHousehold,
      Capability.manageAccounts,
      Capability.manageFinances,
      Capability.manageHomestead,
      Capability.manageTasks,
      Capability.viewHouseholdData,
    },
    UserRole.adult: {
      Capability.manageFinances,
      Capability.manageHomestead,
      Capability.manageTasks,
      Capability.viewHouseholdData,
    },
    UserRole.teen: {
      Capability.manageTasks,
    },
    UserRole.child: {},
  };

  /// Effective capability for [user]: an explicit per-account override
  /// in UserAccount.permissions wins; otherwise falls back to the
  /// role default.
  static bool can(UserAccount user, Capability capability) {
    final override = user.permissions[capability.name];
    if (override != null) return override;
    return _defaults[user.role]?.contains(capability) ?? false;
  }

  /// Returns the role-default capability set, for UI purposes
  /// (e.g. pre-checking toggles in account creation based on the
  /// role picked, before any manual override is made).
  static Set<Capability> defaultsFor(UserRole role) =>
      _defaults[role] ?? const {};
}
