import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/transaction_helper.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/message_utils.dart';
import '../../utils/transaction_utils.dart';
import '../widgets/grouped_transaction_list.dart';
import '/localization/app_localizations_extension.dart'; // Import localization extension

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize the view model when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchViewModel = Provider.of<SearchViewModel>(context, listen: false);
      searchViewModel.setContext(context);
      searchViewModel.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the search view model
    final searchViewModel = Provider.of<SearchViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('search'),
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (searchViewModel.isFilterActive)
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: Colors.orange),
              onPressed: () => searchViewModel.resetFilters(),
              tooltip: context.tr('clear_all_filters'),
            ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(searchViewModel),
          _buildFilterSection(searchViewModel),
          _buildSummarySection(searchViewModel),
          _buildToggleButtons(searchViewModel),
          searchViewModel.isLoading
              ? Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          )
              : Expanded(
            child: _buildSearchResults(searchViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (text) => viewModel.setSearchText(text),
        decoration: InputDecoration(
          hintText: context.tr('search_hint'),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              viewModel.setSearchText('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildFilterSection(SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(viewModel),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _selectDateRange(context, viewModel),
                icon: Icon(Icons.date_range, size: 18),
                label: Text(context.tr('select_date')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (viewModel.startDate != null && viewModel.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      label: Text(
                        '${context.tr('from')}${DateFormat('dd/MM/yyyy').format(viewModel.startDate!)} - ${context.tr('to')}${DateFormat('dd/MM/yyyy').format(viewModel.endDate!)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () => viewModel.setDateRange(null, null),
                      backgroundColor: Colors.orange.shade100,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(SearchViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: viewModel.selectedCategory.isEmpty ? null : viewModel.selectedCategory,
          hint: Text(context.tr('select_category')),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
          style: TextStyle(color: Colors.black, fontSize: 16),
          dropdownColor: Colors.white,
          onChanged: (String? newValue) {
            viewModel.setSelectedCategory(newValue ?? '');
          },
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(context.tr('all_categories')),
            ),
            ...viewModel.availableCategories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(SearchViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem(context.tr('expense'), formatCurrencyWithSymbol(viewModel.expenseTotal), Colors.red.shade200),
          _buildSummaryItem(context.tr('income'), formatCurrencyWithSymbol(viewModel.incomeTotal), Colors.green.shade200),
          _buildSummaryItem(
              context.tr('difference'),
              viewModel.netTotal >= 0
                  ? formatCurrencyWithSymbol(viewModel.netTotal)
                  : '-${formatCurrencyWithSymbol(viewModel.netTotal.abs())}',
              viewModel.netTotal >= 0 ? Colors.green.shade200 : Colors.red.shade200
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color backgroundColor) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons(SearchViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.toggleExpensesIncomeView(true),
            child: Container(
              height: 40,
              color: viewModel.showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                context.tr('expense'),
                style: TextStyle(
                  color: viewModel.showExpenses ? Colors.white : Colors.black,
                  fontWeight: viewModel.showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.toggleExpensesIncomeView(false),
            child: Container(
              height: 40,
              color: !viewModel.showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                context.tr('income'),
                style: TextStyle(
                  color: !viewModel.showExpenses ? Colors.white : Colors.black,
                  fontWeight: !viewModel.showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(SearchViewModel viewModel) {
    // Filter results by expense or income
    List<ExpenseModel> filteredResults = viewModel.searchResults
        .where((item) => item.isExpense == viewModel.showExpenses)
        .toList();

    // Sort by date (newest first)
    filteredResults.sort((a, b) => b.date.compareTo(a.date));

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          viewModel.showExpenses ? context.tr('no_expense_match') : context.tr('no_income_match'),
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return SafeArea(
      bottom: true,
      child: GroupedTransactionList(
        transactions: filteredResults,
        onLongPress: (context, expense) {
          TransactionHelper.showActionMenu(
              context,
              expense,
              viewModel,
              null, // No special callback needed after edit
              null
          );
        },
      ),
    );
  }

  // Select date range
  Future<void> _selectDateRange(BuildContext context, SearchViewModel viewModel) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: viewModel.startDate != null && viewModel.endDate != null
          ? DateTimeRange(start: viewModel.startDate!, end: viewModel.endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.setDateRange(picked.start, picked.end);
    }
  }
}