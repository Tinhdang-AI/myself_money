import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../utils/message_utils.dart';
import '../utils/transaction_utils.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '/localization/app_localizations_extension.dart';

/// Helper class for transaction operations across different screens
class TransactionHelper {
  /// Handle transaction action menu with proper view model handling
  static void showActionMenu<T>(
      BuildContext context,
      ExpenseModel expense,
      T viewModel,
      Future<void> Function(ExpenseModel)? onEditSuccess,
      Future<void> Function(ExpenseModel)? onDeleteSuccess,
      ) {
    TransactionUtils.showActionMenu(
      context,
      expense,
          () => _editTransaction(context, expense, viewModel, onEditSuccess),
          () => _deleteTransaction(context, expense, viewModel, onDeleteSuccess),
    );
  }

  static String translateCategoryIfNeeded(BuildContext context, String categoryName) {
    if (categoryName.startsWith('category_')) {
      return context.tr(categoryName);
    }
    return categoryName;
  }

  static Future<void> _editTransaction<T>(
      BuildContext context,
      ExpenseModel expense,
      T viewModel,
      Future<void> Function(ExpenseModel)? onEditSuccess,
      ) async {
    try {
      // Lấy danh mục từ viewModel
      final categoryList = await _getCategoriesFromViewModel(viewModel);

      // Tạo phiên bản cập nhật của expense với tên danh mục đã dịch để hiển thị
      final displayExpense = expense.copyWith(
          category: translateCategoryIfNeeded(context, expense.category)
      );

      // Hiển thị hộp thoại chỉnh sửa
      final result = await TransactionUtils.showEditDialog(
        context,
        displayExpense,
        categoryList,
      );