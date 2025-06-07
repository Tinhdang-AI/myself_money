import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/transaction_utils.dart';
import '../localization/app_localizations.dart';

class ReportViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  BuildContext? _context;
  AppLocalizations? _l10n;

  bool _isLoading = false;
  bool _isMonthly = true; // Toggle between monthly and yearly view
  bool _hasNoData = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Data
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _incomes = [];
  Map<String, double> _expenseCategoryTotals = {};
  Map<String, double> _incomeCategoryTotals = {};
  Map<String, String> _expenseCategoryOriginalKeys = {};
  Map<String, String> _incomeCategoryOriginalKeys = {};

  // Category details state
  String? _selectedCategory;
  bool _showingCategoryDetails = false;
  bool _isCategoryExpense = true;
  List<ExpenseModel> _categoryTransactions = [];

  // Totals
  double _expenseTotal = 0;
  double _incomeTotal = 0;
  double _netTotal = 0;

  // Tab selection
  int _tabIndex = 0; // 0 for expenses, 1 for incomes

  // Colors for charts
  final List<Color> _expensecolors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.indigo.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
    Colors.brown.shade400,
    Colors.lime.shade400,
  ];

  final List<Color> _incomecolors = [
    Colors.lightGreen.shade400,
    Colors.tealAccent.shade400,
    Colors.blueGrey.shade400,
    Colors.cyan.shade400,
    Colors.lime.shade400,
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isMonthly => _isMonthly;
  bool get hasNoData => _hasNoData;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get incomes => _incomes;
  Map<String, double> get expenseCategoryTotals => _expenseCategoryTotals;
  Map<String, double> get incomeCategoryTotals => _incomeCategoryTotals;
  Map<String, String> get expenseCategoryOriginalKeys => _expenseCategoryOriginalKeys;
  Map<String, String> get incomeCategoryOriginalKeys => _incomeCategoryOriginalKeys;
  String? get selectedCategory => _selectedCategory;
  bool get showingCategoryDetails => _showingCategoryDetails;
  bool get isCategoryExpense => _isCategoryExpense;
  List<ExpenseModel> get categoryTransactions => _categoryTransactions;
  double get expenseTotal => _expenseTotal;
  double get incomeTotal => _incomeTotal;
  double get netTotal => _netTotal;
  int get tabIndex => _tabIndex;
  List<Color> get expensecolors => _expensecolors;
  List<Color> get incomecolors => _incomecolors;

  // Set context for localization
  void setContext(BuildContext context) {
    _context = context;
    _l10n = AppLocalizations.of(context);
  }

  // String translations helper
  String tr(String key, [List<String>? args]) {
    if (_l10n == null) return key;

    String text = _l10n!.translate(key);

    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }

    return text;
  }

  // Initialize
  Future<void> initialize() async {
    _selectedDate = DateTime.now();
    await checkForData();
  }

  // Check if user has any data
  Future<void> checkForData() async {
    _setLoading(true);

    try {
      bool hasData = await _databaseService.hasAnyData();

      if (!hasData) {
        _hasNoData = true;
      } else {
        await loadReportData();
      }
    } catch (e) {
      _setError(tr('error_load_report', [e.toString()]));
      await loadReportData(); // Try loading data anyway
    } finally {
      _setLoading(false);
    }
  }

  // Update selected date
  void updateSelectedDate(DateTime newDate) {
    _selectedDate = newDate;
    _showingCategoryDetails = false;
    notifyListeners();
    loadReportData();
  }

  // Load report data based on selected time period
  Future<void> loadReportData() async {
    _setLoading(true);

    _expenseTotal = 0;
    _incomeTotal = 0;
    _expenses = [];
    _incomes = [];
    _expenseCategoryTotals = {};
    _incomeCategoryTotals = {};
    _showingCategoryDetails = false;

    try {
      if (_isMonthly) {
        await _loadMonthlyData();
      } else {
        await _loadYearlyData();
      }
    } catch (e) {
      _setError(tr('error_load_report', [e.toString()]));
    } finally {
      _setLoading(false);
    }
  }

  // Load monthly data
  Future<void> _loadMonthlyData() async {
    try {
      final List<ExpenseModel> transactions = await _databaseService.getExpensesByMonthFuture(
          _selectedDate.month,
          _selectedDate.year
      );

      _expenses = transactions.where((tx) => tx.isExpense).toList();
      _incomes = transactions.where((tx) => !tx.isExpense).toList();

      _calculateTotals();
      _generateCategoryTotals();

      _hasNoData = transactions.isEmpty;
    } catch (e) {
      _setError(tr('error_load_monthly', [e.toString()]));
    }
  }

  // Load yearly data
  Future<void> _loadYearlyData() async {
    try {
      final List<ExpenseModel> yearlyTransactions = await _databaseService.getExpensesByYearFuture(
          _selectedDate.year
      );

      _expenses = yearlyTransactions.where((tx) => tx.isExpense).toList();
      _incomes = yearlyTransactions.where((tx) => !tx.isExpense).toList();

      _calculateTotals();
      _generateCategoryTotals();

      _hasNoData = yearlyTransactions.isEmpty;
    } catch (e) {
      _setError(tr('error_load_yearly', [e.toString()]));
    }
  }

  // Update time range
  Future<void> updateTimeRange(bool isNext) async {
    if (_isMonthly) {
      // Monthly view
      _selectedDate = DateTime(
        _selectedDate.year,
        isNext ? _selectedDate.month + 1 : _selectedDate.month - 1,
      );
    } else {
      // Yearly view
      _selectedDate = DateTime(
        isNext ? _selectedDate.year + 1 : _selectedDate.year - 1,
        _selectedDate.month,
      );
    }

    _showingCategoryDetails = false;
    notifyListeners();
    await loadReportData();
  }

  // Toggle between monthly and yearly view
  void toggleTimeFrame() {
    _isMonthly = !_isMonthly;
    _showingCategoryDetails = false;
    _selectedDate = DateTime.now(); // Reset to current date
    notifyListeners();
    loadReportData();
  }

  // Calculate totals
  void _calculateTotals() {
    _expenseTotal = _expenses.fold(0, (sum, item) => sum + item.amount);
    _incomeTotal = _incomes.fold(0, (sum, item) => sum + item.amount);
    _netTotal = _incomeTotal - _expenseTotal;
  }

  // Hàm hỗ trợ dịch tên danh mục
  String translateCategoryName(String category) {
    if (category.startsWith('category_')) {
      return tr(category);
    }
    return category;
  }

// Sửa phương thức _generateCategoryTotals()
  void _generateCategoryTotals() {
    // Generate expense category totals
    Map<String, double> expenseTotals = {};
    Map<String, String> expenseCategoryKeys = {}; // Lưu trữ khóa gốc

    for (var item in _expenses) {
      String displayName = translateCategoryName(item.category);
      expenseTotals[displayName] = (expenseTotals[displayName] ?? 0) + item.amount;
      expenseCategoryKeys[displayName] = item.category; // Lưu khóa gốc
    }
    _expenseCategoryTotals = expenseTotals;
    _expenseCategoryOriginalKeys = expenseCategoryKeys; // Lưu khóa gốc

    // Generate income category totals
    Map<String, double> incomeTotals = {};
    Map<String, String> incomeCategoryKeys = {}; // Lưu trữ khóa gốc

    for (var item in _incomes) {
      String displayName = translateCategoryName(item.category);
      incomeTotals[displayName] = (incomeTotals[displayName] ?? 0) + item.amount;
      incomeCategoryKeys[displayName] = item.category; // Lưu khóa gốc
    }
    _incomeCategoryTotals = incomeTotals;
    _incomeCategoryOriginalKeys = incomeCategoryKeys; // Lưu khóa gốc
  }

  // Show category details
  void showCategoryDetails(String categoryDisplayName, bool isExpense) {
    _selectedCategory = categoryDisplayName;
    _isCategoryExpense = isExpense;

    // Lấy khóa gốc từ tên hiển thị
    String originalCategoryKey = isExpense
        ? _expenseCategoryOriginalKeys[categoryDisplayName] ?? categoryDisplayName
        : _incomeCategoryOriginalKeys[categoryDisplayName] ?? categoryDisplayName;

    // Lọc các giao dịch theo danh mục đã chọn (sử dụng khóa gốc)
    _categoryTransactions = isExpense
        ? _expenses.where((expense) => expense.category == originalCategoryKey).toList()
        : _incomes.where((income) => income.category == originalCategoryKey).toList();

    // Sắp xếp theo ngày (mới nhất trước)
    _categoryTransactions.sort((a, b) => b.date.compareTo(a.date));

    _showingCategoryDetails = true;
    notifyListeners();
  }

  // Go back to main report
  void backToMainReport() {
    _showingCategoryDetails = false;
    notifyListeners();
  }

  // Set tab index
  void setTabIndex(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  // Edit transaction
  Future<bool> editTransaction(ExpenseModel expense) async {
    try {
      _setLoading(true);

      final result = await TransactionUtils.editTransaction(expense, _databaseService);

      if (result.success && result.updatedExpense != null) {
        ExpenseModel updatedExpense = result.updatedExpense!;

        // Update in category transactions list if showing details
        if (_showingCategoryDetails) {
          int index = _categoryTransactions.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _categoryTransactions[index] = updatedExpense;
          }

          // If category changed or transaction type changed, remove from details view
          if (updatedExpense.category != _selectedCategory ||
              updatedExpense.isExpense != _isCategoryExpense) {
            _categoryTransactions.removeWhere((item) => item.id == expense.id);
          }
        }

        // Update in main lists
        if (expense.isExpense) {
          int index = _expenses.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _expenses[index] = updatedExpense;
          }
        } else {
          int index = _incomes.indexWhere((item) => item.id == expense.id);
          if (index >= 0) {
            _incomes[index] = updatedExpense;
          }
        }

        // Recalculate totals and category totals
        _calculateTotals();
        _generateCategoryTotals();

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(tr('update_error'));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(ExpenseModel expense) async {
    try {
      _setLoading(true);

      final result = await TransactionUtils.deleteTransaction(expense.id, _databaseService);

      if (result) {
        // Remove from category transactions if showing details
        if (_showingCategoryDetails) {
          _categoryTransactions.removeWhere((item) => item.id == expense.id);

          // If no more transactions, go back to main report
          if (_categoryTransactions.isEmpty) {
            _showingCategoryDetails = false;
          }
        }

        // Remove from main lists
        if (expense.isExpense) {
          _expenses.removeWhere((item) => item.id == expense.id);
        } else {
          _incomes.removeWhere((item) => item.id == expense.id);
        }

        // Recalculate totals and category totals
        _calculateTotals();
        _generateCategoryTotals();

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(tr('delete_error'));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      return await _databaseService.getCategories();
    } catch (e) {
      print("Error getting categories in viewmodel: $e");
      return [];
    }
  }

  // Get color for expense category
  Color getExpenseColor(int index) {
    return _expensecolors[index % _expensecolors.length];
  }

  // Get color for income category
  Color getIncomeColor(int index) {
    return _incomecolors[index % _incomecolors.length];
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
}
