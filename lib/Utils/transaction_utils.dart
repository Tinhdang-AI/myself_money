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
  
  // Show edit dialog
  static Future<EditResult?> showEditDialog(
      BuildContext context,
      ExpenseModel expense,
      List<Map<String, dynamic>> categoryList) {
    final TextEditingController noteController = TextEditingController(text: expense.note);

    // Convert the amount from VND to current currency
    final double convertedAmount = convertFromVND(expense.amount);
    final TextEditingController amountController = TextEditingController(
        text: getCurrentCurrencyFormatter().format(convertedAmount));


    // Keep original date value
    DateTime selectedDate = expense.date;

    // Initialize selected category and category icon
    String selectedCategory = expense.category;
    String selectedCategoryIcon = expense.categoryIcon;

    // Format date as dd/MM/yyyy
    final dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));


    return showDialog<EditResult?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Theme(
            // Apply a custom theme for this dialog
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Colors.orange,
                selectionColor: Colors.orange.withOpacity(0.3),
                selectionHandleColor: Colors.orange,
              ),
            ),
            child: AlertDialog(
              title: Text(context.tr('edit_transaction')),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selection section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.tr('category')}:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        // Tappable container to open category selection dialog
                        GestureDetector(
                          onTap: () {
                            // Show category selection dialog
                            _showCategorySelectionDialog(
                                context,
                                categoryList,
                                expense.isExpense,
                                selectedCategory,
                                    (category, icon) {
                                  setState(() {
                                    selectedCategory = category;
                                    selectedCategoryIcon = icon;
                                  });
                                }
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Display selected category with overflow handling
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        IconData(int.parse(selectedCategoryIcon), fontFamily: 'MaterialIcons'),
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          selectedCategory,
                                          style: TextStyle(fontSize: 16, color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Add icon to indicate it's tappable
                                Icon(Icons.arrow_drop_down, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

