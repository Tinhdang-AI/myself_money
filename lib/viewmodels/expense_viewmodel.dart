import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/cupertino.dart';
import '/localization/app_localizations.dart';
import '/localization/app_localizations_extension.dart';

class ExpenseViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BuildContext? _context;

  // Set context for localization
  void setContext(BuildContext context) {
    _context = context;
  }

  // Get localized string
  String _tr(String key) {
    if (_context != null) {
      return _context!.tr(key);
    }
    return key;
  }

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  // Default categories with localization keys
  List<Map<String, dynamic>> _getDefaultExpenseCategories() {
    return [
      {"icon": Icons.restaurant, "label": _tr('category_food'), "labelKey": "category_food"},
      {"icon": Icons.shopping_bag, "label": _tr('category_shopping'), "labelKey": "category_shopping"},
      {"icon": Icons.checkroom, "label": _tr('category_clothing'), "labelKey": "category_clothing"},
      {"icon": Icons.spa, "label": _tr('category_cosmetics'), "labelKey": "category_cosmetics"},
      {"icon": Icons.wine_bar, "label": _tr('category_entertainment'), "labelKey": "category_entertainment"},
      {"icon": Icons.local_hospital, "label": _tr('category_healthcare'), "labelKey": "category_healthcare"},
      {"icon": Icons.school, "label": _tr('category_education'), "labelKey": "category_education"},
      {"icon": Icons.electrical_services, "label": _tr('category_electricity'), "labelKey": "category_electricity"},
      {"icon": Icons.directions_bus, "label": _tr('category_transport'), "labelKey": "category_transport"},
      {"icon": Icons.phone, "label": _tr('category_communication'), "labelKey": "category_communication"},
      {"icon": Icons.home, "label": _tr('category_housing'), "labelKey": "category_housing"},
      {"icon": Icons.water_drop, "label": _tr('category_water'), "labelKey": "category_water"},
      {"icon": Icons.local_gas_station, "label": _tr('category_fuel'), "labelKey": "category_fuel"},
      {"icon": Icons.computer, "label": _tr('category_technology'), "labelKey": "category_technology"},
      {"icon": Icons.car_repair, "label": _tr('category_repair'), "labelKey": "category_repair"},
      {"icon": Icons.coffee, "label": _tr('category_coffee'), "labelKey": "category_coffee"},
      {"icon": Icons.pets, "label": _tr('category_pets'), "labelKey": "category_pets"},
      {"icon": Icons.cleaning_services, "label": _tr('category_service'), "labelKey": "category_service"},
      {"icon": Icons.build, "label": _tr('category_edit'), "labelKey": "category_edit"},
    ];
  }

  List<Map<String, dynamic>> _getDefaultIncomeCategories() {
    return [
      {"icon": Icons.attach_money, "label": _tr('category_salary'), "labelKey": "category_salary"},
      {"icon": Icons.savings, "label": _tr('category_allowance'), "labelKey": "category_allowance"},
      {"icon": Icons.card_giftcard, "label": _tr('category_bonus'), "labelKey": "category_bonus"},
      {"icon": Icons.trending_up, "label": _tr('category_investment'), "labelKey": "category_investment"},
      {"icon": Icons.account_balance_wallet, "label": _tr('category_other_income'), "labelKey": "category_other_income"},
      {"icon": Icons.work, "label": _tr('category_part_time'), "labelKey": "category_part_time"},
      {"icon": Icons.corporate_fare, "label": _tr('category_commission'), "labelKey": "category_commission"},
      {"icon": Icons.real_estate_agent, "label": _tr('category_real_estate'), "labelKey": "category_real_estate"},
      {"icon": Icons.currency_exchange, "label": _tr('category_exchange'), "labelKey": "category_exchange"},
      {"icon": Icons.dynamic_feed, "label": _tr('category_other'), "labelKey": "category_other"},
      {"icon": Icons.build, "label": _tr('category_edit'), "labelKey": "category_edit"},
    ];
  }

  // List of all available icons for category creation
  final List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.checkroom,
    Icons.spa,
    Icons.wine_bar,
    Icons.local_hospital,
    Icons.school,
    Icons.electrical_services,
    Icons.directions_bus,
    Icons.phone,
    Icons.home,
    Icons.attach_money,
    Icons.pets,
    Icons.theater_comedy,
    Icons.sports_basketball,
    Icons.music_note,
    Icons.movie,
    Icons.flight,
    Icons.fitness_center,
    Icons.shopping_cart,
    Icons.child_care,
    Icons.toys,
    Icons.water_drop,
    Icons.coffee,
    Icons.fastfood,
    Icons.emoji_transportation,
    Icons.park,
    Icons.book,
    Icons.weekend,
    Icons.computer,
    Icons.car_repair,
    Icons.smartphone,
    Icons.local_gas_station,
    Icons.credit_card,
    Icons.subscriptions,
    Icons.sports_esports,
    Icons.cleaning_services,
    Icons.cake,
    Icons.create,
    Icons.style,
    Icons.work,
    Icons.monetization_on,
    Icons.analytics,
    Icons.payments,
    Icons.corporate_fare,
    Icons.dynamic_feed,
    Icons.inventory,
    Icons.savings,
    Icons.card_giftcard,
    Icons.auto_graph,
    Icons.currency_exchange,
    Icons.real_estate_agent,
    Icons.receipt,
    Icons.money,
    Icons.wallet,
    Icons.account_balance,
    Icons.note,
    Icons.insights,
    Icons.pie_chart,
    Icons.flag,
    Icons.lock_clock,
    Icons.settings,
    Icons.history,
    Icons.support_agent,
    Icons.tips_and_updates,
    Icons.label,
    Icons.category,
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get expenseCategories => _expenseCategories;
  List<Map<String, dynamic>> get incomeCategories => _incomeCategories;
  List<IconData> get icons => availableIcons;

  // Reset initialization state - NEW METHOD
  void resetInitializationState() {
    _isInitialized = false;
    _expenseCategories = [];
    _incomeCategories = [];
    notifyListeners();
  }

  // Load categories from Firebase
  Future<void> loadCategories() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setDefaultCategories();
        _isInitialized = true;
        _setLoading(false);
        return;
      }

      String userId = currentUser.uid;

      // Query data from Firestore
      DocumentSnapshot doc = await _firestore.collection('users')
          .doc(userId)
          .get();

      bool hasCategories = false;

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Load expense categories
        if (userData.containsKey('expenseCategories') &&
            userData['expenseCategories'] is List &&
            (userData['expenseCategories'] as List).isNotEmpty) {
          List<dynamic> loadedExpenseCategories = userData['expenseCategories'];
          List<Map<String, dynamic>> parsedExpenseCategories = loadedExpenseCategories.map((item) {
            String labelKey = item["label"] ?? "";
            String label;

            // Check if this is a translation key (starts with "category_")
            if (labelKey.startsWith("category_")) {
              label = _tr(labelKey);
            } else {
              label = labelKey;
            }

            return {
              "label": label,
              "labelKey": labelKey, // Store the original key for saving
              "icon": IconData(item["iconCode"], fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Edit" category exists
          String editLabel = _tr('category_edit');
          if (!parsedExpenseCategories.any((element) => element["labelKey"] == "category_edit")) {
            parsedExpenseCategories.add({
              "icon": Icons.build,
              "label": editLabel,
              "labelKey": "category_edit"
            });
          }

          _expenseCategories = parsedExpenseCategories;
          hasCategories = true;
        }

        // Load income categories
        if (userData.containsKey('incomeCategories') &&
            userData['incomeCategories'] is List &&
            (userData['incomeCategories'] as List).isNotEmpty) {
          List<dynamic> loadedIncomeCategories = userData['incomeCategories'];
          List<Map<String, dynamic>> parsedIncomeCategories = loadedIncomeCategories.map((item) {
            String labelKey = item["label"] ?? "";
            String label;

            // Check if this is a translation key (starts with "category_")
            if (labelKey.startsWith("category_")) {
              label = _tr(labelKey);
            } else {
              label = labelKey;
            }

            return {
              "label": label,
              "labelKey": labelKey, // Store the original key for saving
              "icon": IconData(item["iconCode"], fontFamily: item["fontFamily"] ?? 'MaterialIcons')
            };
          }).toList();

          // Ensure "Edit" category exists
          String editLabel = _tr('category_edit');
          if (!parsedIncomeCategories.any((element) => element["labelKey"] == "category_edit")) {
            parsedIncomeCategories.add({
              "icon": Icons.build,
              "label": editLabel,
              "labelKey": "category_edit"
            });
          }

          _incomeCategories = parsedIncomeCategories;
          hasCategories = true;
        }
      }

      // If user has no categories, use default ones and save to Firebase
      if (!hasCategories) {
        _setDefaultCategories();
        await _saveDefaultCategoriesToFirebase();
      }

      _isInitialized = true;
    } catch (e) {
      _setDefaultCategories();
      _setError(_tr('error_load_categories').replaceAll('{0}', e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // Set default categories
  void _setDefaultCategories() {
    _expenseCategories = _getDefaultExpenseCategories();
    _incomeCategories = _getDefaultIncomeCategories();
  }

  // Save default categories to Firebase
  Future<void> _saveDefaultCategoriesToFirebase() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      String userId = currentUser.uid;

      // Get default categories
      final defaultExpenseCategories = _getDefaultExpenseCategories();
      final defaultIncomeCategories = _getDefaultIncomeCategories();

      // Convert expense categories to serializable format
      List<Map<String, dynamic>> serializableExpenseCategories = defaultExpenseCategories.map((category) {
        return {
          "label": category["labelKey"], // Store the key, not the translated value
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert income categories to serializable format
      List<Map<String, dynamic>> serializableIncomeCategories = defaultIncomeCategories.map((category) {
        return {
          "label": category["labelKey"], // Store the key, not the translated value
          "iconCode": (category["icon"] as IconData).codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set({
        'expenseCategories': serializableExpenseCategories,
        'incomeCategories': serializableIncomeCategories,
        'isDefaultCategoriesSaved': true,
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } catch (e) {
      _setError(_tr('error_default_categories').replaceAll('{0}', e.toString()));
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  // Add a new category
  Future<bool> addCategory(String name, IconData icon, bool isExpense) async {
    // Remove extra whitespace and convert to lowercase for comparison
    name = name.trim();
    String nameLower = name.toLowerCase();

    // Select the appropriate category list
    List<Map<String, dynamic>> targetList = isExpense
        ? _expenseCategories
        : _incomeCategories;

    // Check if category already exists (case insensitive)
    bool categoryExists = targetList.any(
            (category) => category["label"].toString().toLowerCase() == nameLower
    );

    if (categoryExists) {
      _setError(_tr('category_exists'));
      return false;
    }

    if (name.isEmpty) {
      _setError(_tr('enter_category_name'));
      return false;
    }

    try {
      String editLabel = _tr('category_edit');

      // Remove "Edit" entry to add it last
      targetList.removeWhere((element) => element["label"] == editLabel);

      // Add new category with explicit Map<String, Object> casting
      Map<String, Object> newCategory = {
        "icon": icon,
        "label": name,
        "labelKey": name,  // For custom categories, key is the same as label
      };

      targetList.add(newCategory);

      // Add "Edit" entry back with explicit casting
      Map<String, Object> editCategory = {
        "icon": Icons.build,
        "label": editLabel,
        "labelKey": "category_edit"
      };

      targetList.add(editCategory);

      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Save changes to Firebase
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_tr('error_add_category').replaceAll('{0}', e.toString()));
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int index, bool isExpense) async {
    _setLoading(false);

    try {
      List<Map<String, dynamic>> targetList = isExpense ? _expenseCategories : _incomeCategories;

      // Don't allow deleting "Edit" category
      String editLabel = _tr('category_edit');
      if (targetList[index]["label"] == editLabel) {
        return false;
      }

      targetList.removeAt(index);

      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Save changes to Firebase
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_tr('error_delete_category').replaceAll('{0}', e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reorder category method
  Future<bool> reorderCategory(int oldIndex, int newIndex, bool isExpense) async {
    try {
      // Chọn danh sách đúng
      List<Map<String, dynamic>> targetList = isExpense ? _expenseCategories : _incomeCategories;

      // Tách category_edit nếu có
      final editIndex = targetList.indexWhere((cat) => cat["labelKey"] == "category_edit");
      Map<String, dynamic>? editCategory;
      if (editIndex != -1) {
        editCategory = targetList.removeAt(editIndex);
      }

      // Xử lý di chuyển bình thường
      final movedCategory = targetList.removeAt(oldIndex);
      if (newIndex > oldIndex) newIndex -= 1;
      targetList.insert(newIndex, movedCategory);

      // Đảm bảo "category_edit" luôn ở cuối
      if (editCategory != null) {
        targetList.add(editCategory);
      }

      // Gán lại danh sách
      if (isExpense) {
        _expenseCategories = targetList;
      } else {
        _incomeCategories = targetList;
      }

      // Lưu và cập nhật
      await _saveCategoriesToFirebase();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_tr('error_save_category').replaceAll('{0}', e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Save categories to Firebase
  Future<void> _saveCategoriesToFirebase() async {
    _setLoading(false);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setLoading(false);
        return;
      }

      String userId = currentUser.uid;

      // Convert expense categories to serializable format with explicit type
      List<Map<String, Object>> serializableExpenseCategories = _expenseCategories.map((category) {
        IconData icon = category["icon"] as IconData;
        return {
          "label": category["labelKey"] as String, // Use the labelKey for storage
          "iconCode": icon.codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Convert income categories to serializable format with explicit type
      List<Map<String, Object>> serializableIncomeCategories = _incomeCategories.map((category) {
        IconData icon = category["icon"] as IconData;
        return {
          "label": category["labelKey"] as String, // Use the labelKey for storage
          "iconCode": icon.codePoint,
          "fontFamily": "MaterialIcons"
        };
      }).toList();

      // Save to Firestore with explicit Map<String, Object> type
      await _firestore.collection('users').doc(userId).set({
        'expenseCategories': serializableExpenseCategories,
        'incomeCategories': serializableIncomeCategories,
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } catch (e) {
      _setError(_tr('error_save_category').replaceAll('{0}', e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // Add a new transaction
  Future<bool> addTransaction({
    required String note,
    required double amount,
    required String category,
    required String categoryIcon,
    required DateTime date,
    required bool isExpense,
  }) async {
    _setLoading(true);

    try {
      // Find the category's key from the label
      String categoryKey = category;

      // Find the matching category to get its key
      List<Map<String, dynamic>> categories = isExpense ? _expenseCategories : _incomeCategories;
      for (var item in categories) {
        if (item["label"] == category) {
          categoryKey = item["labelKey"];
          break;
        }
      }

      await _databaseService.addExpense(
        note: note,
        amount: amount,
        category: categoryKey, // Store the key instead of display name
        categoryIcon: categoryIcon,
        date: date,
        isExpense: isExpense,
      );

      return true;
    } catch (e) {
      _setError(_tr('error_save_transaction').replaceAll('{0}', e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void refreshCategoryLabels() {
    _expenseCategories = _expenseCategories.map((category) {
      // Update translated label for default categories
      String labelKey = category["labelKey"] ?? "";
      if (labelKey.startsWith("category_")) {
        return {
          "icon": category["icon"],
          "label": _tr(labelKey),
          "labelKey": labelKey
        };
      }
      return category;
    }).toList();

    _incomeCategories = _incomeCategories.map((category) {
      // Update translated label for default categories
      String labelKey = category["labelKey"] ?? "";
      if (labelKey.startsWith("category_")) {
        return {
          "icon": category["icon"],
          "label": _tr(labelKey),
          "labelKey": labelKey
        };
      }

      return category;
    }).toList();

    notifyListeners();
  }
}
