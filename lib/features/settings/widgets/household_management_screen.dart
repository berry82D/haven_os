import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/app_state.dart';

class HouseholdManagementScreen extends StatelessWidget {
  const HouseholdManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pending = appState.joinRequests
        .where((r) => r.status == JoinRequestStatus.pending)
        .toList();
    final isAdmin = appState.isParentAccount;

    return Scaffold(
      backgroundColor: HavenColors.cream,
      appBar: AppBar(
        title: const Text('Household Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Household Members ----------
          const Text(
            'Household Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HavenColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<UserAccount>>(
            future: appState.getHouseholdMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final members = snapshot.data ?? [];

              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No household members found',
                      style: TextStyle(color: HavenColors.muted),
                    ),
                  ),
                );
              }

              return Column(
                children: members.map((member) {
                  final isCurrentUser = member.id == appState.currentUser?.id;
                  final canPromote =
                      isAdmin && !member.isParent && !isCurrentUser;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor:
                            HavenColors.green.withValues(alpha: 0.12),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HavenColors.green,
                          ),
                        ),
                      ),
                      title: Text(
                        member.name + (isCurrentUser ? ' (You)' : ''),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _roleLabel(member),
                        style: const TextStyle(
                          fontSize: 12,
                          color: HavenColors.muted,
                        ),
                      ),
                      trailing: canPromote
                          ? TextButton(
                              onPressed: () =>
                                  _confirmPromote(context, appState, member),
                              child: const Text(
                                'Promote',
                                style: TextStyle(
                                  color: HavenColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // ---------- Pending Join Requests ----------
          const Text(
            'Pending Join Requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HavenColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        size: 40, color: HavenColors.lightMuted),
                    SizedBox(height: 12),
                    Text(
                      'No pending join requests',
                      style: TextStyle(color: HavenColors.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...pending.map((request) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      request.requesterName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(request.requesterName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wants to join "${request.householdName}"'),
                      if (request.message != null &&
                          request.message!.isNotEmpty)
                        Text(
                          'Reason: ${request.message}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          appState.approveJoinRequest(request.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request approved')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          appState.rejectJoinRequest(request.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _roleLabel(UserAccount member) {
    if (member.isParent) return 'Parent / Administrator';
    if (member.isTeen) return 'Teen';
    if (member.isChild) return 'Child';
    return 'Adult';
  }

  Future<void> _confirmPromote(
    BuildContext context,
    AppState appState,
    UserAccount member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promote to Parent?'),
        content: Text(
          'This will give ${member.name} full Parent/Administrator access to the household.\n\n'
          'They will be able to manage accounts, approve requests, and view all household data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Promote',
              style: TextStyle(color: HavenColors.green),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await appState.promoteToParent(member.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} is now a Parent')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not promote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
