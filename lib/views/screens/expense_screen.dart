import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/message_utils.dart';
import '../../views/widgets/app_bottom_navigation_bar.dart';
import '../../views/widgets/custom_date_picker.dart';
import '/localization/app_localizations_extension.dart'; // Import localization extension

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Controllers
  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();

  // State variables
  int selectedTab = 0; // 0: Expense, 1: Income
  DateTime selectedDate = DateTime.now();
  String selectedCategoryLabel = "";
  String selectedCategoryKey = "";
  String selectedCategoryIcon = "";
  IconData? selectedIconForNewCategory;
  bool _isAddingCategory = false;

  @override
  void initState() {
    super.initState();

    // Initialize view model once the widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
      expenseViewModel.setContext(context); // Add this line
      expenseViewModel.loadCategories();
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    amountController.dispose();
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the ExpenseViewModel
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);

    // Get category lists from view model
    final expenseCategories = expenseViewModel.expenseCategories;
    final incomeCategories = expenseViewModel.incomeCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildToggleTab(),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: expenseViewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8B55)))
          : Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!expenseViewModel.isEditMode)
            // Use common date picker widget
              CustomDatePicker(
                selectedDate: selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                backgroundColor: Colors.white,
                textColor: Colors.black,
                showBorder: true,
              ),
            SizedBox(height: 10),
            if (!expenseViewModel.isEditMode) _buildExpenseFields(),
            if (!expenseViewModel.isEditMode) SizedBox(height: 10),
            if (expenseViewModel.isEditMode)
              _buildCategoryEditor(expenseViewModel)
            else
              expenseCategories.isEmpty || incomeCategories.isEmpty
                  ? Center(child: Text(context.tr('loading_categories')))
                  : Expanded(child: _buildCategoryGrid(expenseViewModel)),
            SizedBox(height: 20),
            if (!expenseViewModel.isEditMode) _buildSubmitButton(
                expenseViewModel),
          ],
        ),
      ),
      floatingActionButton: expenseViewModel.isEditMode ? FloatingActionButton(
        backgroundColor: Color(0xFFFF8B55),
        child: Icon(Icons.check, color: Colors.white),
        onPressed: () {
          expenseViewModel.toggleEditMode();
        },
      ) : null,
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 0, // 0 for ExpenseScreen
        onTabSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/report');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/more');
              break;
          }
        },
      ),
    );
  }

  Widget _buildToggleTab() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(context.tr('expense'), 0),
          _buildTabButton(context.tr('income'), 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
            selectedCategoryLabel = "";
            selectedCategoryKey = "";
            selectedCategoryIcon = "";
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFF8B55) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Color(0xFFFF8B55).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              )
            ]
                : null,
          ),

          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  context.tr('note'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Expense/Income with dynamic currency symbol
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  selectedTab == 0 ? context.tr('expense') : context.tr('income'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildCurrencyInputField(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method to handle currency input field with correct symbol placement
  Widget _buildCurrencyInputField() {
    String currencyCode = getCurrentCode();
    String currencySymbol = getCurrentSymbol();

    // Determine symbol position based on currency code
    bool symbolAtStart = currencyCode == 'USD';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (symbolAtStart)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(currencySymbol, style: TextStyle(fontSize: 16)),
          ),

        Expanded(
          child: TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
            ),
            inputFormatters: [
              CurrencyInputFormatter(),
            ],
          ),
        ),

        if (!symbolAtStart)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(currencySymbol, style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid(ExpenseViewModel viewModel) {
    List<Map<String, dynamic>> categories =
    selectedTab == 0 ? viewModel.expenseCategories : viewModel.incomeCategories;

    return Expanded(
        child: GridView.builder(
          padding: EdgeInsets.only(bottom: 8, top: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            bool isSelected = selectedCategoryLabel ==
                categories[index]["label"];
            bool isEditButton = categories[index]["labelKey"] ==
                "category_edit";

            return GestureDetector(
              onTap: () {
                if (isEditButton) {
                  viewModel.toggleEditMode();
                } else {
                  setState(() {
                    selectedCategoryLabel = categories[index]["label"];
                    selectedCategoryKey =
                    categories[index]["labelKey"]; // Store key for saving
                    selectedCategoryIcon =
                        (categories[index]["icon"] as IconData).codePoint
                            .toString();
                  });
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFFFF8B55)
                        : isEditButton
                        ? Colors.grey[300]!
                        : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Color(0xFFFF8B55).withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ]
                      : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFFFF8B55).withOpacity(0.1)
                            : isEditButton
                            ? Colors.grey[100]
                            : Colors.grey[50],
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      child: Icon(
                        categories[index]["icon"],
                        size: 30,
                        color: isSelected || isEditButton
                            ? Color(0xFFFF8B55)
                            : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        categories[index]["label"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight
                              .w500,
                          color: isSelected || isEditButton
                              ? Color(0xFFFF8B55)
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
    );
  }

  Widget _buildCategoryEditor(ExpenseViewModel viewModel) {
    String categoryType = selectedTab == 0
        ? context.tr('expense_category')
        : context.tr('income_category');

    final displayCategories = selectedTab == 0
        ? viewModel.expenseCategories.where((cat) => cat["labelKey"] != "category_edit").toList()
        : viewModel.incomeCategories.where((cat) => cat["labelKey"] != "category_edit").toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('edit_categories', [categoryType]),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      context.tr('add_new_category'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      )
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: categoryNameController,
                          decoration: InputDecoration(
                            hintText: context.tr('category_name'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12
                            ),
                          ),
                          enabled: !_isAddingCategory,
                        ),
                      ),
                      SizedBox(width: 12),

                      GestureDetector(
                        onTap: _isAddingCategory ? null : _showIconSelector,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: _isAddingCategory
                                ? Colors.grey.shade200
                                : Colors.grey.shade100,
                          ),
                          child: Center(
                            child: selectedIconForNewCategory != null
                                ? Icon(selectedIconForNewCategory,
                                size: 32,
                                color: _isAddingCategory
                                    ? Colors.grey
                                    : Color(0xFFFF8B55))
                                : Icon(Icons.add_circle_outline,
                                size: 32,
                                color: _isAddingCategory
                                    ? Colors.grey
                                    : Color(0xFFFF8B55)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      ElevatedButton(
                        onPressed: _isAddingCategory ? null : () => _addNewCategory(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF8B55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16
                          ),
                        ),
                        child: _isAddingCategory
                            ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                        )
                            : Text(
                          context.tr('add'),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),

          Text(
              context.tr('current_categories'),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              )
          ),

          SizedBox(height: 6),

          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: viewModel.isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8B55)))
                    : ReorderableListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                    final category = displayCategories[index];

                    return ListTile(
                      key: ValueKey(category["labelKey"]),
                      leading: Icon(
                          category["icon"],
                          size: 30,
                          color: Colors.orange
                      ),
                      title: Text(
                        category["label"],
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                                Icons.delete,
                                color: Colors.red
                            ),
                            onPressed: () {
                              // Find the actual index in original list
                              final originalList = selectedTab == 0
                                  ? viewModel.expenseCategories
                                  : viewModel.incomeCategories;

                              int originalIndex = originalList.indexWhere(
                                      (cat) => cat["labelKey"] == category["labelKey"]);

                              if (originalIndex >= 0) {
                                _deleteCategory(viewModel, originalIndex);
                              }
                            },
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                                Icons.drag_handle,
                                color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    viewModel.reorderCategory(oldIndex, newIndex, selectedTab == 0);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ExpenseViewModel viewModel) {
    return Center(
      child: ElevatedButton(
        onPressed: viewModel.isLoading ? null : () => _saveExpense(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF8B55),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        child: viewModel.isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          selectedTab == 0
              ? context.tr('add_expense')
              : context.tr('add_income'),
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Show icon selector dialog
  void _showIconSelector() {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('select_icon')),
          backgroundColor: Colors.white,
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: viewModel.icons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIconForNewCategory = viewModel.icons[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(viewModel.icons[index], size: 30),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
          ],
        );
      },
    );
  }


// Add a new category
  Future<void> _addNewCategory(ExpenseViewModel viewModel) async {
    if (categoryNameController.text.isEmpty ||
        selectedIconForNewCategory == null) {
      MessageUtils.showErrorMessage(
          context, context.tr('enter_category_icon'));
      return;
    }

    setState(() {
      _isAddingCategory = true;
    });

    final success = await viewModel.addCategory(
        categoryNameController.text.trim(),
        selectedIconForNewCategory!,
        selectedTab == 0 // true for expense, false for income
    );

    setState(() {
      _isAddingCategory = false;
    });

    if (!success) {
      // If adding fails, display error from ViewModel
      if (viewModel.errorMessage != null) {
        MessageUtils.showErrorMessage(context, viewModel.errorMessage!);
      }
    } else {
      setState(() {
        categoryNameController.clear();
        selectedIconForNewCategory = null;
      });
      MessageUtils.showSuccessMessage(
          context, context.tr('add_category_success'));
    }
  }

  // Delete a category
  Future<void> _deleteCategory(ExpenseViewModel viewModel, int index) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: context.tr('confirm'),
      message: context.tr('confirm_delete_category'),
      confirmLabel: context.tr('delete'),
      cancelLabel: context.tr('cancel'),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteCategory(
          index,
          selectedTab == 0 // true for expense, false for income
      );

      if (success) {
        MessageUtils.showSuccessMessage(context, context.tr('delete_category_success'));
      }
    }
  }

  // Save expense
  Future<void> _saveExpense(ExpenseViewModel viewModel) async {
    if (amountController.text.isEmpty || selectedCategoryLabel.isEmpty) {
      MessageUtils.showErrorMessage(
          context, context.tr('enter_amount_category'));
      return;
    }

    double amount = parseFormattedCurrency(amountController.text);
    if (amount <= 0) {
      MessageUtils.showErrorMessage(context, context.tr('amount_greater_than_zero'));
      return;
    }

    // Convert to storage currency (VND)
    double amountInVND = convertToVND(amount);

    final success = await viewModel.addTransaction(
      note: noteController.text,
      amount: amountInVND,
      category: selectedCategoryLabel,
      categoryIcon: selectedCategoryIcon,
      date: selectedDate,
      isExpense: selectedTab == 0,
    );

    if (success) {
      // Reset form
      setState(() {
        noteController.clear();
        amountController.clear();
        selectedCategoryLabel = "";
        selectedCategoryKey = "";
        selectedCategoryIcon = "";
      });

      String type = selectedTab == 0 ? context.tr('expense') : context.tr('income');
      MessageUtils.showSuccessMessage(
          context,
          context.tr('add_transaction_success', [type])
      );
    }
  }
}