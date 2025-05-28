import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/localization/app_localizations_extension.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool showMonthInfo;
  final Color? backgroundColor;
  final Color? textColor;
  final Color arrowColor;
  final bool showBorder;

  const CustomDatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    this.showMonthInfo = false,
    this.backgroundColor,
    this.textColor,
    this.arrowColor = const Color(0xFFFF8B55),
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthRange = _getMonthRangeText(selectedDate);
    // Calculate the date limit (30 days from now)
    final DateTime maxDate = DateTime.now().add(const Duration(days: 30));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            context.tr('tab_calendar'),
            style: TextStyle(
              color: textColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: showBorder ? Border.all(color: arrowColor) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: TextStyle(
                        color: textColor ?? Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showMonthInfo) ...[
                      const SizedBox(height: 2),
                      Text(
                        monthRange,
                        style: TextStyle(
                          color: textColor ?? Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildNavigationButton(
            icon: Icons.chevron_right,
            // Only allow forward navigation if the next day is within the 30-day limit
            onPressed: selectedDate.add(const Duration(days: 1)).isAfter(maxDate)
                ? null  // Disable button if next day exceeds limit
                : () => onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: onPressed == null ? Colors.grey : arrowColor, // Grey out if disabled
      ),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 20,
    );
  }

  String _getMonthRangeText(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return "${DateFormat('MM/yyyy').format(date)} (${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)})";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFF8B55), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}