import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [
    {
      'id': '1',
      'name': 'Corn Feed',
      'quantity': 500,
      'unit': 'lbs',
      'category': 'Feed'
    },
    {
      'id': '2',
      'name': 'Hay Bales',
      'quantity': 25,
      'unit': 'bales',
      'category': 'Feed'
    },
    {
      'id': '3',
      'name': 'Fencing Wire',
      'quantity': 10,
      'unit': 'rolls',
      'category': 'Equipment'
    },
    {
      'id': '4',
      'name': 'Water Trough',
      'quantity': 3,
      'unit': 'units',
      'category': 'Equipment'
    },
  ];

  void _addItem() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    String category = 'Feed';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number),
            TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                    labelText: 'Unit (e.g., lbs, bales)')),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: ['Feed', 'Equipment', 'Supplies', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              final unit = unitCtrl.text.trim();
              if (name.isNotEmpty && qty > 0) {
                setState(() {
                  _items.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': name,
                    'quantity': qty,
                    'unit': unit,
                    'category': category,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: const Text('📦 Inventory'),
        backgroundColor: AppTheme.paper,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No inventory items.\nTap the + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.ink, fontFamily: 'serif'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppTheme.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.tornEdge, width: 0.5),
                  ),
                  child: ListTile(
                    title: Text(item['name'],
                        style: const TextStyle(
                            fontFamily: 'serif', fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        '${item['quantity']} ${item['unit']} • ${item['category']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(i),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
