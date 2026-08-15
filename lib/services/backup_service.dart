import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/models/loan.dart';
import 'package:haven_os/models/feed_delivery.dart';
import 'package:haven_os/models/budget.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/models/household.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/models/guardian_relationship.dart';

class BackupService {
  static const String version = '1.0.0';

  static Map<String, dynamic> buildBackupData({
    required List<Transaction> transactions,
    required List<Animal> animals,
    required List<Bill> bills,
    required List<Task> tasks,
    required List<TimelineEvent> timelineEvents,
    required List<Loan> loans,
    required List<FeedDelivery> feedDeliveries,
    required List<Budget> budgets,
    required List<UserAccount> accounts,
    required List<Household> households,
    required List<JoinRequest> joinRequests,
    required List<GuardianRelationship> guardianRelationships,
  }) {
    return {
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'animals': animals.map((a) => a.toJson()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'timelineEvents': timelineEvents.map((e) => e.toJson()).toList(),
      'loans': loans.map((l) => l.toJson()).toList(),
      'feedDeliveries': feedDeliveries.map((f) => f.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'households': households.map((h) => h.toJson()).toList(),
      'joinRequests': joinRequests.map((r) => r.toJson()).toList(),
      'guardianRelationships':
          guardianRelationships.map((g) => g.toJson()).toList(),
    };
  }

  /// Export – works on both mobile and desktop
  static Future<String?> exportBackup(Map<String, dynamic> data) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final fileName =
          'haven_os_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json';

      // On mobile we save to the app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Import – uses the modern FilePicker API
  static Future<Map<String, dynamic>> importBackup() async {
    try {
      // file_picker 10.3.9+ removed the instance-based .platform
      // accessor (breaking change upstream) in favor of calling
      // static methods directly on FilePicker.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // important for mobile
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = result.files.single;
      String jsonString;

      if (file.bytes != null) {
        // Mobile / web path
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // Desktop path
        jsonString = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read the selected file');
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['version'] != version) {
        throw Exception('Incompatible backup version (expected $version)');
      }

      return data;
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }
}
