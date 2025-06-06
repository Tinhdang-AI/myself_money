import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../models/expense_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/message_utils.dart';
import '../../utils/transaction_utils.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import '../widgets/grouped_transaction_list.dart';
import '../../utils/transaction_helper.dart';
import '/localization/app_localizations_extension.dart';
import '../widgets/month_picker.dart';
import '../widgets/year_picker.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize the report view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportViewModel = Provider.of<ReportViewModel>(context, listen: false);
      reportViewModel.initialize();

      // Listen for tab changes
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          reportViewModel.setTabIndex(_tabController!.index);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportViewModel = Provider.of<ReportViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(reportViewModel),
      body: Column(
        children: [
          reportViewModel.isMonthly
              ? MonthPicker(
            selectedDate: reportViewModel.selectedDate,
            focusedDate: reportViewModel.selectedDate,
            onDateChanged: (DateTime newDate) {
              reportViewModel.updateSelectedDate(newDate);
            },
            onMonthChanged: (int direction) {
              reportViewModel.updateTimeRange(direction > 0);
            },
          )
              : CustomYearPicker(
            selectedDate: reportViewModel.selectedDate,
            focusedDate: reportViewModel.selectedDate,
            onDateChanged: (DateTime newDate) {
              reportViewModel.updateSelectedDate(newDate);
            },
            onYearChanged: (int direction) {
              reportViewModel.updateTimeRange(direction > 0);
            },
          ),
          _buildSummaryBox(reportViewModel),
          if (!reportViewModel.hasNoData && !reportViewModel.showingCategoryDetails)
            _buildTabBar(),
          Expanded(
            child: reportViewModel.isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : reportViewModel.hasNoData
                ? _buildNoDataView()
                : reportViewModel.showingCategoryDetails
                ? _buildCategoryDetailsView(reportViewModel)
                : _buildReportContent(reportViewModel),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 2, // 2 for ReportScreen
        onTabSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/expense');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/more');
              break;
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ReportViewModel viewModel) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: _buildTimeToggle(viewModel),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
        ),
      ],
    );
  }

  Widget _buildTimeToggle(ReportViewModel viewModel) {
    return Container(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!viewModel.isMonthly) {
                  viewModel.toggleTimeFrame();
                }
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: viewModel.isMonthly ? Color(0xFFFF8B55) : Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                child: Text(
                  context.tr('monthly'),
                  style: TextStyle(
                    color: viewModel.isMonthly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (viewModel.isMonthly) {
                  viewModel.toggleTimeFrame();
                }
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !viewModel.isMonthly ? Color(0xFFFF8B55) : Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Text(
                  context.tr('yearly'),
                  style: TextStyle(
                    color: !viewModel.isMonthly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(ReportViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row: Expense and Income boxes
          Row(
            children: [
              // Expense box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('expense_total'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formatCurrencyWithSymbol(viewModel.expenseTotal),
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Income box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('income_total'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formatCurrencyWithSymbol(viewModel.incomeTotal),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Second row: Balance box
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('balance'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    viewModel.netTotal >= 0
                        ? '+${formatCurrencyWithSymbol(viewModel.netTotal)}'
                        : '-${formatCurrencyWithSymbol(viewModel.netTotal.abs())}',
                    style: TextStyle(
                      color: viewModel.netTotal >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(
          child: Text(
            context.tr('expense'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Tab(
          child: Text(
          context.tr('income'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ),
      ],
      labelColor: Color(0xFFFF8B55),
      unselectedLabelColor: Colors.black54,
      indicatorColor: Color(0xFFFF8B55),
    );
  }

  Widget _buildReportContent(ReportViewModel viewModel) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExpenseTab(viewModel),
        _buildIncomeTab(viewModel),
      ],
    );
  }

  Widget _buildExpenseTab(ReportViewModel viewModel) {
    // Get expense categories data
    Map<String, double> categoryData = viewModel.expenseCategoryTotals;

    // If no data available
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_expense_data', [viewModel.isMonthly ? context.tr('month') : context.tr('year')]),
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort categories by amount
    List<MapEntry<String, double>> sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        // Pie chart section
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _buildPieChart(sortedCategories, totalAmount, viewModel, isExpense: true),
        ),
        // Divider
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        // Categories list section
        Expanded(
          child: ListView.separated(
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final percentage = (totalAmount > 0)
                  ? (category.value / totalAmount * 100)
                  : 0;
              String displayName = category.key;
              if (displayName.startsWith('category_')) {
                displayName = context.tr(displayName);
              }

              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: viewModel.getExpenseColor(index),
                    shape: BoxShape.circle,
                  ),
                ),

                title: Text(
                  displayName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(viewModel.getExpenseColor(index)),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(category.value),
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () => viewModel.showCategoryDetails(category.key, true),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildIncomeTab(ReportViewModel viewModel) {
    // Get income categories data
    Map<String, double> categoryData = viewModel.incomeCategoryTotals;

    // If no data available
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_income_data', [viewModel.isMonthly ? context.tr('month') : context.tr('year')]),
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort categories by amount
    List<MapEntry<String, double>> sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryData.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: [
        // Pie chart section
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _buildPieChart(sortedCategories, totalAmount, viewModel, isExpense: false),
        ),
        // Divider
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        // Categories list section
        Expanded(
          child: ListView.separated(
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final percentage = (totalAmount > 0)
                  ? (category.value / totalAmount * 100)
                  : 0;
              String displayName = category.key;
              if (displayName.startsWith('category_')) {
                displayName = context.tr(displayName);
              }

              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: viewModel.getIncomeColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(viewModel.getIncomeColor(index)),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(category.value),
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                onTap: () => viewModel.showCategoryDetails(category.key, false),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildPieChart(
      List<MapEntry<String, double>> categories,
      double totalAmount,
      ReportViewModel viewModel,
      {required bool isExpense}) {

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: List.generate(
          categories.length,
              (index) {
            final category = categories[index];
            final percentage = (category.value / totalAmount) * 100;
            final color = isExpense
                ? viewModel.getExpenseColor(index)
                : viewModel.getIncomeColor(index);

            return PieChartSectionData(
              value: category.value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 50,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: color,
              badgePositionPercentageOffset: .98,
            );
          },
        ),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle tap on pie chart sections
            if (event is FlTapUpEvent && pieTouchResponse != null &&
                pieTouchResponse.touchedSection != null) {
              final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              if (touchedIndex >= 0 && touchedIndex < categories.length) {
                viewModel.showCategoryDetails(categories[touchedIndex].key, isExpense);
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDetailsView(ReportViewModel viewModel) {
    final totalAmount = viewModel.categoryTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final color = viewModel.isCategoryExpense ? Colors.red : Colors.green;

    // Format time range display
    String timeRangeDisplay = viewModel.isMonthly
        ? '${context.tr('month_' + viewModel.selectedDate.month.toString())} ${viewModel.selectedDate.year}'
        : '${context.tr('year')} ${viewModel.selectedDate.year}';

    String displayCategoryName = viewModel.selectedCategory ?? '';
    if (displayCategoryName.startsWith('category_')) {
      displayCategoryName = context.tr(displayCategoryName);
    }

    return Column(
      children: [
        // Header with back button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => viewModel.backToMainReport(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayCategoryName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                formatCurrencyWithSymbol(totalAmount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Time range display
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          child: Center(
            child: Text(
              timeRangeDisplay,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),

        // Transaction list grouped by date
        Expanded(
          child: viewModel.categoryTransactions.isEmpty
              ? Center(
            child: Text(
              context.tr('no_data'),
              style: TextStyle(color: Colors.grey),
            ),
          )
              : GroupedTransactionList(
            transactions: viewModel.categoryTransactions,
            onLongPress: (context, expense) =>
                TransactionHelper.showActionMenu(
                    context,
                    expense,
                    viewModel,
                    null,
                    null
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            context.tr('no_data_time_range'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/expense');
            },
            icon: Icon(Icons.add),
            label: Text(context.tr('add_transaction')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}