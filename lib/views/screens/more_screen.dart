import '../../viewmodels/expense_viewmodel.dart';
import '/localization/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/language_selector.dart';
import '/viewmodels/more_viewmodel.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/views/widgets/app_bottom_navigation_bar.dart';
import '/views/screens/search_screen.dart';
import '/utils/message_utils.dart';
import '/utils/currency_formatter.dart';

class MoreScreen extends StatefulWidget {
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize the view model when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moreViewModel = Provider.of<MoreViewModel>(context, listen: false);
      moreViewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access view models
    final moreViewModel = Provider.of<MoreViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr('more'), style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 3,
        onTabSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/expense');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/report');
              break;
            case 3:
            // Already on this screen, do nothing
              break;
          }
        },
      ),
      body: moreViewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SafeArea(
        child: Column(
          children: [
            _buildUserHeader(moreViewModel),
            SizedBox(height: 10),
            _buildStats(moreViewModel),
            Expanded(
              child: _buildMenuList(context, moreViewModel, authViewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(MoreViewModel viewModel) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 5, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProfileAvatar(viewModel, radius: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  viewModel.userEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (viewModel.userJoinDate.isNotEmpty) SizedBox(height: 5),
                if (viewModel.userJoinDate.isNotEmpty)
                  Text(
                    context.tr('joined_date', [viewModel.userJoinDate]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                _buildCurrencyDisplay(),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.orange),
            onPressed: () => _updateUserProfile(viewModel),
          ),
        ],
      ),
    );
  }

  // Show feedback dialog
  void _showFeedbackDialog(BuildContext context, MoreViewModel viewModel) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(context.tr('send_feedback')),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('feedback_description')),
                SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.tr('enter_feedback'),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (controller.text
                      .trim()
                      .isNotEmpty) {
                    final success = await viewModel.submitFeedback(
                        controller.text.trim());

                    if (success) {
                      MessageUtils.showSuccessMessage(
                          context,
                          context.tr('feedback_success')
                      );
                    }
                  }
                },
                child: Text(context.tr('send')),
              ),
            ],
          ),
    );
  }

  // Show about dialog
  void _showAboutDialog(BuildContext context, MoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(context.tr('about_app')),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                    context.tr('app_description'),
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 10),
                Text(context.tr('version', [viewModel.appVersion])),
                SizedBox(height: 10),
                Text(context.tr('app_intro')),
                SizedBox(height: 15),
                Text(
                    context.tr('features'),
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 5),
                Text(context.tr('feature_1')),
                Text(context.tr('feature_2')),
                Text(context.tr('feature_3')),
                Text(context.tr('feature_4')),
                Text(context.tr('feature_5')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('close')),
              ),
            ],
          ),
    );
  }

  // Show change password dialog
  void _showChangePasswordDialog(BuildContext context,
      AuthViewModel authViewModel) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChangingPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool obscureText1 = true;
            bool obscureText2 = true;
            bool obscureText3 = true;

            return AlertDialog(
              title: Text(context.tr('change_password')),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChangingPassword)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.orange),
                              SizedBox(height: 16),
                              Text(
                                  context.tr('processing'),
                                  style: TextStyle(color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: currentPasswordController,
                            obscureText: obscureText1,
                            decoration: InputDecoration(
                              labelText: context.tr('current_password'),
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    obscureText1 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText1 = !obscureText1),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: newPasswordController,
                            obscureText: obscureText2,
                            decoration: InputDecoration(
                              labelText: context.tr('new_password'),
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    obscureText2 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText2 = !obscureText2),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureText3,
                            decoration: InputDecoration(
                              labelText: context.tr('confirm_password'),
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    obscureText3 ? Icons.visibility : Icons
                                        .visibility_off),
                                onPressed: () =>
                                    setDialogState(() =>
                                    obscureText3 = !obscureText3),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: isChangingPassword ? [] : [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (currentPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('enter_current_password')
                      );
                      return;
                    }

                    if (newPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('enter_new_password')
                      );
                      return;
                    }

                    if (confirmPasswordController.text.isEmpty) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('confirm_new_password')
                      );
                      return;
                    }

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('password_not_match')
                      );
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('password_min_length')
                      );
                      return;
                    }

                    if (currentPasswordController.text ==
                        newPasswordController.text) {
                      MessageUtils.showErrorMessage(
                          context,
                          context.tr('password_same')
                      );
                      return;
                    }

                    // Update state to show loading
                    setDialogState(() {
                      isChangingPassword = true;
                    });

                    // Update password using view model
                    final success = await authViewModel.updatePassword(
                        currentPasswordController.text,
                        newPasswordController.text
                    );

                    if (success) {
                      Navigator.pop(dialogContext);
                      MessageUtils.showSuccessMessage(
                          context,
                          context.tr('change_password_success')
                      );
                    } else {
                      // Error message is already shown by the view model
                      setDialogState(() {
                        isChangingPassword = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange
                  ),
                  child: Text(context.tr('update')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Confirm reset app
  Future<void> _confirmResetApp(BuildContext context,
      MoreViewModel viewModel) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: context.tr('reset_app_confirm'),
      message: context.tr('reset_app_description'),
      confirmLabel: context.tr('reset'),
      cancelLabel: context.tr('cancel'),
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      final success = await viewModel.resetApp();

      if (success) {
        MessageUtils.showSuccessMessage(
            context,
            context.tr('reset_success')
        );
      }
    }
  }

  // Logout
  Future<void> _logout(BuildContext context, MoreViewModel viewModel) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: context.tr('logout'),
      message: context.tr('confirm_logout'),
      confirmLabel: context.tr('logout'),
      cancelLabel: context.tr('cancel'),
    );

    if (confirmed == true) {

      final expenseViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
      expenseViewModel.resetInitializationState();

      final success = await viewModel.signOut();

      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Widget _buildProfileAvatar(MoreViewModel viewModel,
      {required double radius}) {
    if (viewModel.profileImageUrl.isEmpty) {
      return _buildDefaultAvatar(viewModel.userName, radius);
    }

    // Check if it's a Firebase URL (base64 encoded) or a network image
    bool isFirebaseImage = !viewModel.profileImageUrl.startsWith('http');

    if (isFirebaseImage) {
      return FutureBuilder<String?>(
        future: viewModel.getProfileImage(viewModel.profileImageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.orange.shade200,
              child: SizedBox(
                width: radius * 0.7,
                height: radius * 0.7,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.orange.shade200,
              backgroundImage: MemoryImage(
                  viewModel.base64ToImage(snapshot.data!)),
            );
          }

          return _buildDefaultAvatar(viewModel.userName, radius);
        },
      );
    } else {
      // Network image
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.orange.shade200,
        backgroundImage: NetworkImage(viewModel.profileImageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
  }

  Widget _buildDefaultAvatar(String name, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.orange.shade200,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay() {
    String code = getCurrentCode();
    String symbol = getCurrentSymbol();
    String currencyName = _getCurrencyName(context,code);

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            size: 14,
            color: Colors.grey.shade700,
          ),
          SizedBox(width: 4),
          Text(
            context.tr('currency_unit', [currencyName, symbol]),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencyName(BuildContext context, String code) {
    final Map<String, String> currencyNames = {
      'VND': context.tr('currency_vnd'),
      'USD': context.tr('currency_usd'),
      'EUR': context.tr('currency_eur'),
      'GBP': context.tr('currency_gbp'),
      'JPY': context.tr('currency_jpy'),
      'CNY': context.tr('currency_cny'),
      'KRW': context.tr('currency_krw'),
      'SGD': context.tr('currency_sgd'),
      'THB': context.tr('currency_thb'),
      'MYR': context.tr('currency_myr'),
    };

    return currencyNames[code] ?? context.tr('currency_vnd');
  }

  Widget _buildStats(MoreViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context.tr('transactions'),
            '${viewModel.totalTransactions}',
            Icons.receipt_long,
          ),
          _buildStatItem(
            context.tr('this_month'),
            '${viewModel.monthTransactions}',
            Icons.date_range,
          ),
          _buildStatItem(
            context.tr('total_balance'),
            formatCurrencyWithSymbol(viewModel.totalBalance),
            Icons.account_balance_wallet,
            valueColor: viewModel.totalBalance >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context, MoreViewModel moreViewModel,
      AuthViewModel authViewModel) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildExpansionTile(context.tr('account'), Icons.person, [
          _buildSubMenuItem(context.tr('change_password'), Icons.lock_open, () {
            _showChangePasswordDialog(context, authViewModel);
          }),
          _buildSubMenuItem(
              context.tr('logout'), Icons.logout, () =>
              _logout(context, moreViewModel)),
        ]),
        _buildMenuItem(context.tr('currency'), Icons.currency_exchange, () {
          _showCurrencySelector(context, moreViewModel);
        }),

        LanguageSelector(),

        _buildMenuItem(context.tr('reset_app'), Icons.restore, () {
          _confirmResetApp(context, moreViewModel);
        }),
        _buildMenuItem(context.tr('about'), Icons.info_outline, () {
          _showAboutDialog(context, moreViewModel);
        }),
        _buildMenuItem(context.tr('feedback'), Icons.feedback, () {
          _showFeedbackDialog(context, moreViewModel);
        }),
      ],
    );
  }

  Widget _buildExpansionTile(String title, IconData icon,
      List<Widget> children) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: TextStyle(fontSize: 16)),
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 32, right: 16),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(icon, size: 18, color: Colors.grey.shade700),
        onTap: onTap,
      ),
    );
  }

  // Update user profile
  Future<void> _updateUserProfile(MoreViewModel viewModel) async {
    String newName = viewModel.userName;

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(context.tr('update_profile')),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.updateProfileImage();
                    _updateUserProfile(viewModel);
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildProfileAvatar(viewModel, radius: 40),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: context.tr('display_name'),
                    hintText: context.tr('enter_display_name'),
                  ),
                  onChanged: (value) {
                    newName = value;
                  },
                  controller: TextEditingController(text: viewModel.userName),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  if (newName
                      .trim()
                      .isNotEmpty && newName != viewModel.userName) {
                    bool success = await viewModel.updateUserProfile(newName);

                    if (success) {
                      MessageUtils.showSuccessMessage(
                          context, context.tr('update_success'));
                    }
                  }
                },
                child: Text(context.tr('update')),
              ),
            ],
          ),
    );
  }

  // Show currency selector dialog
  void _showCurrencySelector(BuildContext context, MoreViewModel viewModel) {
    // Common currencies
    final List<Map<String, String>> currencies = [
      {'code': 'VND', 'symbol': 'đ', 'name': context.tr('currency_vnd')},
      {'code': 'USD', 'symbol': '\$', 'name': context.tr('currency_usd')},
      {'code': 'EUR', 'symbol': '€', 'name': context.tr('currency_eur')},
      {'code': 'GBP', 'symbol': '£', 'name': context.tr('currency_gbp')},
      {'code': 'JPY', 'symbol': '¥', 'name': context.tr('currency_jpy')},
      {'code': 'CNY', 'symbol': '¥', 'name': context.tr('currency_cny')},
      {'code': 'KRW', 'symbol': '₩', 'name': context.tr('currency_krw')},
      {'code': 'SGD', 'symbol': 'S\$', 'name': context.tr('currency_sgd')},
      {'code': 'THB', 'symbol': '฿', 'name': context.tr('currency_thb')},
      {'code': 'MYR', 'symbol': 'RM', 'name': context.tr('currency_myr')},
    ];

    // Get current currency code
    String selectedCurrencyCode = getCurrentCode();

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(context.tr('select_currency')),
                backgroundColor: Colors.white,
                content: Container(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currencies.length,
                    itemBuilder: (context, index) {
                      final currency = currencies[index];
                      final bool isSelected = currency['code'] ==
                          selectedCurrencyCode;

                      return ListTile(
                        leading: Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            currency['symbol']!,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(currency['name']!),
                        subtitle: Text(currency['code']!),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedCurrencyCode = currency['code']!;
                          });
                        },
                        selected: isSelected,
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Find the selected currency
                      final selectedCurrency = currencies.firstWhere(
                            (c) => c['code'] == selectedCurrencyCode,
                        orElse: () => currencies.first,
                      );

                      Navigator.pop(context);

                      final success = await viewModel.updateCurrency(
                          selectedCurrency['code']!,
                          selectedCurrency['symbol']!,
                          selectedCurrency['name']!
                      );

                      if (success) {
                        MessageUtils.showSuccessMessage(
                            context,
                            context.tr(
                                'currency_updated', [selectedCurrency['name']!])
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(context.tr('save')),
                  ),
                ],
              );
            },
          ),
    );
  }
}