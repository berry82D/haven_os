import 'package:flutter/material.dart';
import 'package:haven_os/features/cfo/widgets/bills_tab.dart';
import 'package:haven_os/features/cfo/widgets/transactions_tab.dart';
import 'package:haven_os/core/constants/colors.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ledger'),
          backgroundColor: HavenColors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bills', icon: Icon(Icons.receipt)),
              Tab(text: 'Transactions', icon: Icon(Icons.swap_horiz)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BillsTab(),
            TransactionsTab(),
          ],
        ),
      ),
    );
  }
}
