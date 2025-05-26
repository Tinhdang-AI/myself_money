import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import 'currency_formatter.dart';
import 'message_utils.dart';
import '/localization/app_localizations_extension.dart';

class TransactionUtils {
  // Edit a transaction
  static Future<TransactionResult> editTransaction(
      ExpenseModel expense,
      DatabaseService databaseService) async {
    try {
      // Get the updated expense from the database after update
      await databaseService.updateExpense(expense);

      return TransactionResult(
        success: true,
        updatedExpense: expense,
      );