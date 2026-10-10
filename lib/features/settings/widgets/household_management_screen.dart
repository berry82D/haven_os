// lib/features/settings/widgets/household_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/models/household.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/domain/services/household_service.dart';

class HouseholdManagementScreen extends StatefulWidget {
  const HouseholdManagementScreen({super.key});

  @override
  State<HouseholdManagementScreen> createState() =>
      _HouseholdManagementScreenState();
}

class _HouseholdManagementScreenState extends State<HouseholdManagementScreen> {
  late Future<List<UserAccount>> _membersFuture;
  Household? _household;
  bool _loadingHousehold = true;
  final _joinCodeCtrl = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final householdId = appState.currentUser?.householdId ?? '';
    _membersFuture = appState.getHouseholdMembers(householdId);
    _loadHousehold();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHousehold() async {
    setState(() => _loadingHousehold = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final id = appState.currentUser?.householdId ?? '';
    Household? hh;
    if (id.isNotEmpty && id != 'pending_join' && id != 'default') {
      hh = await HouseholdService.getHouseholdById(id);
    }
    if (!mounted) return;
    setState(() {
      _household = hh;
      _loadingHousehold = false;
    });
  }

  Future<void> _createMyHousehold() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return;
    try {
      final hh = await HouseholdService.createHouseholdRecord(
        "${user.name}'s Household",
        ownerUserId: user.id,
      );
      final updated = UserAccount(
        id: user.id,
        householdId: hh.id,
        name: user.name,
        type: user.type,
        role: user.role,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      );
      appState.setCurrentUser(updated);
      setState(() {
        _household = hh;
        _membersFuture = appState.getHouseholdMembers(hh.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Household created. Code: ${hh.inviteCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _joinWithCode() async {
    final code = _joinCodeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code')),
      );
      return;
    }
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return;

    setState(() => _joining = true);
    try {
      final hh = await HouseholdService.joinByInviteCode(
        inviteCode: code,
        userId: user.id,
      );
      final updated = UserAccount(
        id: user.id,
        householdId: hh.id,
        name: user.name,
        type: user.type,
        role: user.role,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      );
      appState.setCurrentUser(updated);
      setState(() {
        _household = hh;
        _membersFuture = appState.getHouseholdMembers(hh.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${hh.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pending = appState.joinRequests
        .where((r) => r.status == JoinRequestStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Invite code (you share with Candice) ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingHousehold
                  ? const Center(child: CircularProgressIndicator())
                  : _household == null || _household!.inviteCode.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'No household yet',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create one to get an invite code for your partner.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _createMyHousehold,
                              child: const Text('Create household'),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _household!.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Invite code (share with partner)'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _household!.inviteCode,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy',
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                          text: _household!.inviteCode),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Code copied')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Join someone else's household ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Join a household',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Enter the code your partner shows you.'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _joinCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'HAVEN-XXXX',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _joining ? null : _joinWithCode,
                    child: _joining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Join with code'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Pending join requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No pending join requests'),
            )
          else
            ...pending.map((request) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      request.requesterName.isNotEmpty
                          ? request.requesterName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(request.requesterName),
                  subtitle: Text(request.householdName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
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
          const SizedBox(height: 16),

          const Text(
            'Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<UserAccount>>(
            future: _membersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return const Text('No members listed yet');
              }
              return Column(
                children: members
                    .map(
                      (user) => ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.role.name),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
