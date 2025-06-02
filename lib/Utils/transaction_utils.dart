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
        } catch (e) {
      print("Error updating transaction: $e");
      return TransactionResult(
        success: false,
        errorMessage: "Error updating transaction: ${e.toString()}",
      );
    }
  }

  // Delete a transaction
  static Future<bool> deleteTransaction(
      String expenseId,
      DatabaseService databaseService) async {
    try {
      await databaseService.deleteExpense(expenseId);
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }

  // Show action menu for a transaction
  static void showActionMenu(
      BuildContext context,
      ExpenseModel expense,
      Function onEdit,
      Function onDelete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text(context.tr('edit_transaction')),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(context.tr('delete_transaction')),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text(context.tr('cancel')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }