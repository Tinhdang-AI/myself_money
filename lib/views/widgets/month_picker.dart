import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/localization/app_localizations_extension.dart';

class MonthPicker extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onMonthChanged;

  const MonthPicker({
    Key? key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  _MonthPickerState createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  late DateTime _tempFocusedDate;

  @override
  void initState() {
    super.initState();
    _tempFocusedDate = widget.focusedDate;
  }

  String _getMonthRangeText(DateTime date) {
    return DateFormat('MM/yyyy').format(date);
  }

  Future<void> _selectMonthAndYear(BuildContext context) async {
    // Reset temp focused date to current focused date at the start of selection
    setState(() {
      _tempFocusedDate = widget.focusedDate;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      context.tr('select_month'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Year Selection Box
                    GestureDetector(
                      onTap: () {
                        _showYearSelectionOverlay(
                            context,
                            _tempFocusedDate.year,
                                (selectedYear) {
                              setState(() {
                                _tempFocusedDate = DateTime(
                                    selectedYear,
                                    _tempFocusedDate.month,
                                    1
                                );
                              });
                            }
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tempFocusedDate.year.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 28,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Month Selection Grid
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(12, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _tempFocusedDate = DateTime(
                                  _tempFocusedDate.year,
                                  index + 1,
                                  1
                              );
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _tempFocusedDate.month == index + 1
                                  ? Color(0xFFFF8B55)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _tempFocusedDate.month == index + 1
                                    ? Color(0xFFFF8B55)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              context.tr('month_abbr_${index + 1}'), // Use localized month names
                              style: TextStyle(
                                color: _tempFocusedDate.month == index + 1
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: _tempFocusedDate.month == index + 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.tr('cancel'),
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Only update when "Chọn" is pressed
                            widget.onDateChanged(_tempFocusedDate);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8B55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            context.tr('confirm'),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showYearSelectionOverlay(
      BuildContext context,
      int initialYear,
      Function(int) onYearSelected
      ) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final screenSize = MediaQuery.of(context).size;
    ScrollController yearScrollController = ScrollController(
      initialScrollOffset: (initialYear - 2000) * 50.0,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: screenSize.width * 0.85,
              height: screenSize.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.tr('select_year'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: yearScrollController,
                      itemCount: 101, // 2000 to 2100
                      itemBuilder: (context, index) {
                        int year = 2000 + index;
                        return ListTile(
                          title: Text(
                            year.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: initialYear == year
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: initialYear == year
                                  ? Color(0xFFFF8B55)
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            onYearSelected(year);
                            overlayEntry.remove();
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => overlayEntry.remove(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8B55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('close'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final monthRange = _getMonthRangeText(widget.focusedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF8B55),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => widget.onMonthChanged(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectMonthAndYear(context),
              child: Text(
                monthRange,
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
            onPressed: () => widget.onMonthChanged(1),
          ),
        ],
      ),
    );
  }
}