
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
