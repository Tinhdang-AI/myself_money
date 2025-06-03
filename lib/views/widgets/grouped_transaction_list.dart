import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';
import '/localization/app_localizations_extension.dart';

class GroupedTransactionList extends StatelessWidget {
  final List<ExpenseModel> transactions;
  final Function(BuildContext, ExpenseModel) onLongPress;
  final bool enableLongPress;

  const GroupedTransactionList({
    Key? key,
    required this.transactions,
    required this.onLongPress,
    this.enableLongPress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize date formatting for multiple locales
    initializeDateFormatting();

    // Group transactions by date
    Map<String, List<ExpenseModel>> groupedTransactions = {};
    for (var transaction in transactions) {
      // Format date based on the current locale
      String date = _formatDateWithLocale(context, transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    return ListView.builder(
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        String date = groupedTransactions.keys.elementAt(index);
        List<ExpenseModel> dayTransactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: dayTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final transaction = dayTransactions[index];
                final bool hasNote = transaction.note.trim().isNotEmpty;

                final String displayCategory = _getDisplayCategory(context, transaction.category);

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    onLongPress: enableLongPress
                        ? () => onLongPress(context, transaction)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Category icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconData(int.parse(transaction.categoryIcon), fontFamily: 'MaterialIcons'),
                              color: transaction.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (hasNote)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      transaction.note,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Amount
                          Text(
                            formatCurrencyWithSymbol(transaction.amount),
                            style: TextStyle(
                              color: transaction.isExpense ? Colors.red : Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getDisplayCategory(BuildContext context, String category) {
    if (category.startsWith("category_")) {
      return context.tr(category);
    }
    return category;
  }

  // Format date based on the current locale
  String _formatDateWithLocale(BuildContext context, DateTime date) {
    // Get the current locale code from the context
    final locale = Localizations.localeOf(context).languageCode;

    // Format the date part (day/month/year)
    final dateFormatter = DateFormat('d/M/yyyy', locale);
    String formattedDate = dateFormatter.format(date);

    // Get localized weekday name
    String weekdayName = _getLocalizedWeekday(context, date.weekday);

    // Combine date with weekday
    return '$formattedDate ($weekdayName)';
  }

  // Get localized weekday name based on weekday number (1-7)
  String _getLocalizedWeekday(BuildContext context, int weekday) {
    // Map weekday number to translation key
    String weekdayKey;
    switch (weekday) {
      case 1:
        weekdayKey = 'monday_full';
        break;
      case 2:
        weekdayKey = 'tuesday_full';
        break;
      case 3:
        weekdayKey = 'wednesday_full';
        break;
      case 4:
        weekdayKey = 'thursday_full';
        break;
      case 5:
        weekdayKey = 'friday_full';
        break;
      case 6:
        weekdayKey = 'saturday_full';
        break;
      case 7:
        weekdayKey = 'sunday_full';
        break;
      default:
        return '';
    }

    // Get translated weekday name
    return context.tr(weekdayKey);
  }
}