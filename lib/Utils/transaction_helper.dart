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

      if (result != null && result.updated) {
        // Xác định xem có nên giữ lại khóa gốc nếu đây là một danh mục hệ thống
        String updatedCategory = result.category;
        String categoryIcon = result.categoryIcon;

        // Tìm danh mục gốc từ danh sách
        for (var category in categoryList) {
          // Kiểm tra nếu đây là danh mục được chọn
          String catName = category['name'] ?? '';
          String displayName = catName.startsWith('category_')
              ? context.tr(catName)
              : catName;

          if (displayName == result.category) {
            // Nếu tìm thấy, sử dụng tên khóa gốc thay vì tên hiển thị
            updatedCategory = catName;
            break;
          }
        }

        // Tạo expense đã cập nhật
        final updatedExpense = expense.copyWith(
          note: result.note,
          amount: result.amount,
          date: result.date,
          category: updatedCategory,
          categoryIcon: categoryIcon,
        );

        final success = await _updateTransactionInViewModel(viewModel, updatedExpense);

        if (success) {
          // Wait a bit for animations to complete and data to update
          await Future.delayed(Duration(milliseconds: 300));

          if (context.mounted) {
            String type = updatedExpense.isExpense
                ? context.tr('expense')
                : context.tr('income');

            // Use MessageUtils instead of ScaffoldMessenger
            MessageUtils.showSuccessMessage(
                context,
                context.tr('transaction_updated', [type])
            );
          }

          // Call optional success callback
          if (onEditSuccess != null) {
            await onEditSuccess(updatedExpense);
          }
        } else {
          // Display error message if update fails
          if (context.mounted) {
            // Use MessageUtils instead of ScaffoldMessenger
            MessageUtils.showErrorMessage(
                context,
                context.tr('update_error')
            );
          }
        }
      }
    } catch (e) {
      print("Error editing transaction: $e");
      if (context.mounted) {
        // Use MessageUtils instead of ScaffoldMessenger
        MessageUtils.showErrorMessage(
            context,
            "${context.tr('error')}: ${e.toString()}"
        );
      }
    }
  }