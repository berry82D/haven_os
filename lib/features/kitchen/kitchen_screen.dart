import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction.dart';

class PantryItem {
  String name;
  double quantity;
  double pricePerUnit;

  PantryItem({
    required this.name,
    required this.quantity,
    this.pricePerUnit = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        name: json['name'],
        quantity: json['quantity'],
        pricePerUnit: json['pricePerUnit'] ?? 0.0,
      );
}

class KitchenScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const KitchenScreen({super.key, required this.transactions});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _recipes = [];
  bool _isSearching = false;
  String _searchMessage = 'Search for a recipe or browse by cuisine.';

  String _selectedCuisine = 'All';
  bool _quickFilter = false;

  final List<String> _cuisineList = [
    'All',
    'Italian',
    'Greek',
    'American',
    'Mexican',
    'Asian',
    'French',
    'Spanish',
    'Indian',
    'Thai',
    'Japanese',
  ];

  Set<String> _favorites = {};
  Map<String, PantryItem> _pantry = {};
  List<String> _shoppingList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
    _loadPantry();
    _loadShoppingList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('kitchen_favorites') ?? [];
    setState(() => _favorites = favs.toSet());
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kitchen_favorites', _favorites.toList());
  }

  Future<void> _loadPantry() async {
    final prefs = await SharedPreferences.getInstance();
    final pantryJson = prefs.getString('kitchen_pantry');
    if (pantryJson != null) {
      final List<dynamic> decoded = jsonDecode(pantryJson);
      setState(() {
        _pantry = {};
        for (var item in decoded) {
          final p = PantryItem.fromJson(item);
          _pantry[p.name] = p;
        }
      });
    }
  }

  Future<void> _savePantry() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _pantry.values.map((p) => p.toJson()).toList();
    await prefs.setString('kitchen_pantry', jsonEncode(list));
  }

  Future<void> _loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('kitchen_shopping_list') ?? [];
    setState(() => _shoppingList = list);
  }

  Future<void> _saveShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kitchen_shopping_list', _shoppingList);
  }

  void _importFromReceipts() {
    final groceryTxs = widget.transactions.where((tx) {
      return tx.category.toLowerCase() == 'groceries' &&
          tx.type == TransactionType.expense &&
          tx.note.contains('Scanned from receipt');
    }).toList();

    if (groceryTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No scanned grocery receipts found. Scan one from the Home screen first!'),
        ),
      );
      return;
    }

    int addedCount = 0;
    for (var tx in groceryTxs) {
      final lines = tx.note.split('\n');
      for (var line in lines) {
        String trimmed = line.trim();
        if (trimmed.isEmpty ||
            trimmed == 'Scanned from receipt' ||
            trimmed == 'Scanned from receipt') continue;
        String item = trimmed.replaceAll(RegExp(r'\d+\.\d{2}'), '').trim();
        if (item.isNotEmpty && !RegExp(r'^\d+$').hasMatch(item)) {
          final name = item.toLowerCase();
          if (_pantry.containsKey(name)) {
            _pantry[name]!.quantity += 1.0;
          } else {
            _pantry[name] =
                PantryItem(name: name, quantity: 1.0, pricePerUnit: 0.0);
          }
          addedCount++;
        }
      }
    }

    if (addedCount > 0) {
      _savePantry();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported $addedCount items from ${groceryTxs.length} receipt(s).'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No items could be parsed from receipts.')),
      );
    }
  }

  Future<void> _searchRecipes() async {
    String query = _searchCtrl.text.trim();

    if (query.isEmpty && _selectedCuisine != 'All') {
      query = _selectedCuisine.toLowerCase();
    } else if (query.isNotEmpty && _selectedCuisine != 'All') {
      query += ' $_selectedCuisine';
    }

    if (_quickFilter) {
      query += ' quick';
    }

    if (query.isEmpty) {
      setState(() {
        _searchMessage = 'Please enter a search term or select a cuisine.';
        _recipes = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchMessage = 'Searching for "$query"...';
    });

    try {
      final url =
          Uri.parse('https://themealdb.com/api/json/v1/1/search.php?s=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> results = [];
        if (data['meals'] != null) {
          results = data['meals'];
        }

        if (_quickFilter) {
          results = results.where((meal) {
            String instructions = meal['strInstructions'] ?? '';
            List<String> steps = instructions
                .split(RegExp(r'\r\n|\n|\.'))
                .where((s) => s.trim().isNotEmpty)
                .toList();
            return steps.length <= 5;
          }).toList();
        }

        if (results.isNotEmpty) {
          setState(() {
            _recipes = results;
            _isSearching = false;
            _searchMessage = 'Found ${_recipes.length} recipes.';
          });
        } else {
          setState(() {
            _recipes = [];
            _isSearching = false;
            _searchMessage = 'No recipes found. Try a different combination.';
          });
        }
      } else {
        setState(() {
          _recipes = [];
          _isSearching = false;
          _searchMessage = 'Error: Could not reach server.';
        });
      }
    } catch (e) {
      setState(() {
        _recipes = [];
        _isSearching = false;
        _searchMessage = 'Error: $e';
      });
    }
  }

  void _toggleFavorite(String recipeId) {
    setState(() {
      if (_favorites.contains(recipeId)) {
        _favorites.remove(recipeId);
      } else {
        _favorites.add(recipeId);
      }
    });
    _saveFavorites();
  }

  double _parseMeasure(String measure) {
    String numPart = measure.split(' ').first.trim();
    if (numPart.contains('/')) {
      final parts = numPart.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        if (denominator != 0) return numerator / denominator;
      }
    } else if (numPart.contains(' ')) {
      final subParts = numPart.split(' ');
      final whole = double.tryParse(subParts[0]) ?? 0;
      final frac = subParts.length > 1 ? _parseMeasure(subParts[1]) : 0;
      return whole + frac;
    }
    return double.tryParse(numPart) ?? 0.0;
  }

  String _scaleMeasure(String originalMeasure, double scale) {
    if (originalMeasure.isEmpty || scale == 1.0) return originalMeasure;
    double numericValue = _parseMeasure(originalMeasure);
    if (numericValue == 0) return originalMeasure;
    double scaledValue = numericValue * scale;
    String unit = originalMeasure.contains(' ')
        ? originalMeasure.substring(originalMeasure.indexOf(' '))
        : '';
    return '${scaledValue.toStringAsFixed(1)} $unit'.trim();
  }

  void _showRecipeDetail(Map<String, dynamic> recipe) {
    int originalServings =
        int.tryParse(recipe['strServings']?.toString() ?? '') ?? 4;
    int currentServings = originalServings;

    List<Map<String, String>> baseIngredients = [];
    for (int i = 1; i <= 20; i++) {
      String ingredient = recipe['strIngredient$i'] ?? '';
      String measure = recipe['strMeasure$i'] ?? '';
      if (ingredient.isNotEmpty && ingredient.trim() != '') {
        baseIngredients.add({
          'name': ingredient.trim(),
          'measure': measure.trim(),
        });
      }
    }

    String instructions =
        recipe['strInstructions'] ?? 'No instructions available.';
    List<String> steps = instructions
        .split(RegExp(r'\r\n|\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (steps.isEmpty) steps = [instructions];

    final isFav = _favorites.contains(recipe['idMeal']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setStateSheet) {
              double scaleFactor = currentServings / originalServings;

              List<Map<String, String>> scaledIngredients =
                  baseIngredients.map((item) {
                String scaledMeasure =
                    _scaleMeasure(item['measure']!, scaleFactor);
                return {
                  'name': item['name']!,
                  'measure': scaledMeasure,
                };
              }).toList();

              double totalCost = 0.0;
              int costCount = 0;
              Map<int, bool> haveIngredient = {};
              for (int i = 0; i < scaledIngredients.length; i++) {
                final name = scaledIngredients[i]['name']!.toLowerCase();
                final pantryItem = _pantry[name];
                if (pantryItem != null && pantryItem.quantity > 0) {
                  haveIngredient[i] = true;
                  totalCost += pantryItem.pricePerUnit * scaleFactor;
                  costCount++;
                } else {
                  haveIngredient[i] = false;
                }
              }

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        recipe['strMealThumb'] ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe['strMeal'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 30,
                          ),
                          onPressed: () {
                            _toggleFavorite(recipe['idMeal']);
                            setStateSheet(() {});
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Cuisine: ${recipe['strArea'] ?? 'N/A'}  |  Category: ${recipe['strCategory'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '👨‍👩‍👧‍👦 Servings:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (currentServings > 1) {
                                  setStateSheet(() {
                                    currentServings--;
                                  });
                                }
                              },
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$currentServings',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setStateSheet(() {
                                  currentServings++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '💰 Estimated Cost',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            costCount > 0
                                ? '\$${totalCost.toStringAsFixed(2)}'
                                : 'N/A (set prices in Pantry)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: costCount > 0
                                  ? Colors.green.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🛒 Ingredients',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children:
                            scaledIngredients.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var item = entry.value;
                          return CheckboxListTile(
                            title: Text('${item['measure']} ${item['name']}'),
                            value: haveIngredient[idx] ?? false,
                            onChanged: (value) {
                              setStateSheet(() {
                                haveIngredient[idx] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              List<String> missing = [];
                              for (int i = 0;
                                  i < scaledIngredients.length;
                                  i++) {
                                if (!(haveIngredient[i] ?? false)) {
                                  missing.add(scaledIngredients[i]['name']!
                                      .toLowerCase());
                                }
                              }
                              if (missing.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('You have all ingredients!')),
                                );
                                return;
                              }
                              setState(() {
                                for (var item in missing) {
                                  if (!_shoppingList.contains(item)) {
                                    _shoppingList.add(item);
                                  }
                                }
                                _saveShoppingList();
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Added ${missing.length} items to shopping list.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Add Missing to Shopping List'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '👨‍🍳 Step-by-Step Instructions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...steps.asMap().entries.map((entry) {
                      int index = entry.key;
                      String step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style:
                                    const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- FIXED PANTRY TAB (with SingleChildScrollView to prevent overflow) ----------
  Widget _buildPantryTab() {
    final _itemCtrl = TextEditingController();
    final _qtyCtrl = TextEditingController();
    final _priceCtrl = TextEditingController();

    return SingleChildScrollView(
      // <-- WRAPPED IN SCROLL VIEW
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _itemCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty (lb)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price \$/lb',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final name = _itemCtrl.text.trim().toLowerCase();
                  final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
                  final price = double.tryParse(_priceCtrl.text) ?? 0.0;
                  if (name.isEmpty) return;
                  setState(() {
                    if (_pantry.containsKey(name)) {
                      _pantry[name]!.quantity += qty;
                      if (price > 0) _pantry[name]!.pricePerUnit = price;
                    } else {
                      _pantry[name] = PantryItem(
                        name: name,
                        quantity: qty,
                        pricePerUnit: price,
                      );
                    }
                    _savePantry();
                  });
                  _itemCtrl.clear();
                  _qtyCtrl.clear();
                  _priceCtrl.clear();
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _importFromReceipts,
            icon: const Icon(Icons.receipt_long),
            label: const Text('Import items from scanned receipts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _pantry.isEmpty
              ? const Center(
                  child: Text(
                      'Pantry is empty. Add items or import from receipts.'),
                )
              : ListView.builder(
                  shrinkWrap: true, // <-- FIXED: allows the list to shrink
                  physics:
                      const NeverScrollableScrollPhysics(), // <-- FIXED: disable inner scroll
                  itemCount: _pantry.length,
                  itemBuilder: (context, index) {
                    final entry = _pantry.entries.toList()[index];
                    final item = entry.value;
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          'Price: \$${item.pricePerUnit.toStringAsFixed(2)} / lb'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${item.quantity.toStringAsFixed(1)} lb'),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {
                              final priceCtrl = TextEditingController(
                                text: item.pricePerUnit.toString(),
                              );
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Set Price'),
                                  content: TextField(
                                    controller: priceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Price per lb (\$)',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final price =
                                            double.tryParse(priceCtrl.text);
                                        if (price != null) {
                                          setState(() {
                                            item.pricePerUnit = price;
                                            _savePantry();
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                if (item.quantity > 1) {
                                  item.quantity -= 1;
                                } else {
                                  _pantry.remove(item.name);
                                }
                                _savePantry();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _pantry.remove(item.name);
                                _savePantry();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ---------- FIXED SHOPPING LIST TAB ----------
  Widget _buildShoppingListTab() {
    return SingleChildScrollView(
      // <-- WRAPPED IN SCROLL VIEW
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shoppingList.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items to buy:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _shoppingList.clear();
                      _saveShoppingList();
                    });
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.red),
                  label: const Text('Clear All',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          const SizedBox(height: 8),
          _shoppingList.isEmpty
              ? const Center(child: Text('Shopping list is empty.'))
              : ListView.builder(
                  shrinkWrap: true, // <-- FIXED
                  physics: const NeverScrollableScrollPhysics(), // <-- FIXED
                  itemCount: _shoppingList.length,
                  itemBuilder: (context, index) {
                    final item = _shoppingList[index];
                    return CheckboxListTile(
                      title: Text(item),
                      value: false,
                      onChanged: (checked) {
                        if (checked == true) {
                          setState(() {
                            _shoppingList.removeAt(index);
                            _saveShoppingList();
                          });
                          if (!_pantry.containsKey(item)) {
                            _pantry[item] = PantryItem(
                                name: item, quantity: 1.0, pricePerUnit: 0.0);
                          } else {
                            _pantry[item]!.quantity += 1.0;
                          }
                          _savePantry();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added $item to pantry.')),
                          );
                        }
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ---------- FIXED RECIPES TAB ----------
  Widget _buildRecipesTab() {
    return SingleChildScrollView(
      // <-- WRAPPED IN SCROLL VIEW
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search recipes (e.g., "pasta")',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _searchRecipes(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Cuisine',
                    border: OutlineInputBorder(),
                  ),
                  initialValue:
                      _selectedCuisine, // <-- FIXED deprecated 'value'
                  onChanged: (value) {
                    setState(() {
                      _selectedCuisine = value!;
                    });
                  },
                  items: _cuisineList.map((cuisine) {
                    return DropdownMenuItem<String>(
                      value: cuisine,
                      child: Text(cuisine),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Checkbox(
                      value: _quickFilter,
                      onChanged: (value) {
                        setState(() {
                          _quickFilter = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Under 30 mins',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (_pantry.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Pantry is empty. Add some items first.')),
                );
                return;
              }
              final ingredients = _pantry.keys.join(',');
              _searchCtrl.text = ingredients;
              _searchRecipes();
            },
            icon: const Icon(Icons.kitchen),
            label: const Text('Find recipes from my pantry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _recipes.isEmpty
              ? Center(
                  child: Text(
                    _searchMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true, // <-- FIXED
                  physics: const NeverScrollableScrollPhysics(), // <-- FIXED
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    final isFav = _favorites.contains(recipe['idMeal']);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            recipe['strMealThumb'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                        title: Text(recipe['strMeal'] ?? 'Untitled'),
                        subtitle: Text(
                            '${recipe['strArea'] ?? 'N/A'} • ${recipe['strCategory'] ?? 'N/A'}'),
                        trailing: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(recipe['idMeal']),
                        ),
                        onTap: () => _showRecipeDetail(recipe),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Kitchen Brain'),
        backgroundColor: Colors.orange.shade700,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Recipes'),
            Tab(icon: Icon(Icons.kitchen), text: 'Pantry'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Shopping'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecipesTab(),
          _buildPantryTab(),
          _buildShoppingListTab(),
        ],
      ),
    );
  }
}
