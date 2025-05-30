import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/localization/app_localizations_extension.dart';

class CustomYearPicker extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onYearChanged;

  const CustomYearPicker({
    Key? key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateChanged,
    required this.onYearChanged,
  }) : super(key: key);

  @override
  _CustomYearPickerState createState() => _CustomYearPickerState();
}

class _CustomYearPickerState extends State<CustomYearPicker> {
  late ScrollController _scrollController;
  final int _startYear = 2000;
  final int _endYear = 2100;

  @override
  void initState() {
    super.initState();
    // Initialize scroll controller to show current year
    _scrollController = ScrollController(
      initialScrollOffset: (widget.focusedDate.year - _startYear) * 50.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectYear(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title
                Text(
                  context.tr('select_year'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Year Selection List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _endYear - _startYear + 1,
                    itemBuilder: (context, index) {
                      int year = _startYear + index;
                      return ListTile(
                        title: Text(
                          year.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: widget.focusedDate.year == year
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: widget.focusedDate.year == year
                                ? Color(0xFFFF8B55)
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          // Create a new DateTime with the selected year
                          DateTime newDate = DateTime(
                              year,
                              widget.focusedDate.month,
                              1
                          );
                          widget.onDateChanged(newDate);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8B55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF8B55),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => widget.onYearChanged(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectYear(context),
              child: Text(
                widget.focusedDate.year.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => widget.onYearChanged(1),
          ),
        ],
      ),
    );
  }
}