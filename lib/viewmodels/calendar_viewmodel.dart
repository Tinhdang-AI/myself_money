
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/transaction_utils.dart';
import '../localization/app_localizations.dart';

class CalendarViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  BuildContext? _context;
  AppLocalizations? _l10n;

  bool _isLoading = false;
  bool _showDateSelector = false;
  String? _errorMessage;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<ExpenseModel> _selectedDayExpenses = [];
  Map<DateTime, List<ExpenseModel>> _eventsByDay = {};

  double _incomeTotal = 0;
  double _expenseTotal = 0;
  double _netTotal = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get showDateSelector => _showDateSelector;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  List<ExpenseModel> get selectedDayExpenses => _selectedDayExpenses;
  Map<DateTime, List<ExpenseModel>> get eventsByDay => _eventsByDay;
  double get incomeTotal => _incomeTotal;
  double get expenseTotal => _expenseTotal;
  double get netTotal => _netTotal;

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

  // Initialize with current date data
  Future<void> initialize() async {
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    await loadMonthData();
    await loadSelectedDayData();
  }

  // Load month data
  Future<void> loadMonthData() async {
    _setLoading(true);

    try {
      final int month = _focusedDay.month;
      final int year = _focusedDay.year;

      // Clear the previous map to avoid stale data
      _eventsByDay = {};

      final expenses = await _databaseService.getExpensesByMonthFuture(month, year);

      // Group transactions by day
      Map<DateTime, List<ExpenseModel>> eventsMap = {};

      for (var expense in expenses) {
        // Ensure consistent date normalization (strip time part)
        final date = DateTime(expense.date.year, expense.date.month, expense.date.day);

        if (eventsMap[date] == null) {
          eventsMap[date] = [];
        }
        eventsMap[date]!.add(expense);
      }

      _eventsByDay = eventsMap;
      notifyListeners();
    } catch (e) {
      _setError(tr('error_load_monthly', [e.toString()]));
    } finally {
      _setLoading(false);
    }
  }

  // Load selected day data
  Future<void> loadSelectedDayData() async {
    _setLoading(true);

    try {
      _selectedDayExpenses = [];
      _incomeTotal = 0;
      _expenseTotal = 0;
      _netTotal = 0;

      final expenses = await _databaseService.getExpensesByDateFuture(_selectedDay);

      _selectedDayExpenses = expenses;
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      _setError(tr('error_load_report', [e.toString()]));
    } finally {
      _setLoading(false);
    }
  }

  // Calculate totals for selected day
  void _calculateTotals() {
    double income = 0;
    double expense = 0;

    for (var item in _selectedDayExpenses) {
      if (item.isExpense) {
        expense += item.amount;
      } else {
        income += item.amount;
      }
    }

    _incomeTotal = income;
    _expenseTotal = expense;
    _netTotal = income - expense;
  }

  // Change month
  Future<void> changeMonth(int step) async {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + step, 1);

    // If selected day is outside the new month, adjust it
    if (_selectedDay.month != _focusedDay.month || _selectedDay.year != _focusedDay.year) {
      _selectedDay = DateTime(_focusedDay.year, _focusedDay.month,
          min(_selectedDay.day, _getDaysInMonth(_focusedDay.year, _focusedDay.month)));
    }

    notifyListeners();
    await loadMonthData();
    await loadSelectedDayData();
  }
// Get days in month
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Helper function for min value
  int min(int a, int b) {
    return a < b ? a : b;
  }

  // Select a day
  Future<void> selectDay(DateTime day) async {
    _selectedDay = day;
    notifyListeners();
    await loadSelectedDayData();
  }

  // Select date with date picker
  Future<void> selectDate(DateTime? date) async {
    if (date == null) return;

    _selectedDay = date;

    // If month changes, update focused day and reload month data
    if (date.month != _focusedDay.month || date.year != _focusedDay.year) {
      _focusedDay = DateTime(date.year, date.month, 1);
      await loadMonthData();
    }

    notifyListeners();
    await loadSelectedDayData();
  }

  // Get expenses for a specific day
  List<ExpenseModel> getExpensesForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _eventsByDay[date] ?? [];
  }

  // Edit transaction
  Future<bool> editTransaction(ExpenseModel expense, TransactionUpdateCallback onSuccess) async {
    try {
      _setLoading(true);

      // Step 1: Update the transaction in the database
      final result = await TransactionUtils.editTransaction(expense, _databaseService);

      if (result.success && result.updatedExpense != null) {
        final updatedExpense = result.updatedExpense!;

        _eventsByDay.clear();
        _selectedDayExpenses.clear();

        await loadMonthData();
        await loadSelectedDayData();

        onSuccess(updatedExpense);

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
