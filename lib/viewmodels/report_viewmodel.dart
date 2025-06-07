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


