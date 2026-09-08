import 'package:flutter/material.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/features/cfo/widgets/bills_tab.dart';
import 'package:haven_os/features/cfo/widgets/transactions_tab.dart';

class LedgerScreen extends StatelessWidget {
  final int initialTab;
  const LedgerScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bills & Transactions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bills'),
              Tab(text: 'Transactions'),
            ],
            labelColor: HavenColors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: HavenColors.green,
          ),
        ),
        body: const TabBarView(
          children: [
            BillsTab(),
            TransactionsTab(),
          ],
        ),
      ),
    );
  }
}