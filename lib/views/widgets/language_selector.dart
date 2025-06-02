import '../../viewmodels/expense_viewmodel.dart';
import '/localization/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/message_utils.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.language, color: Colors.orange),
        title: Text(context.tr('language'), style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showLanguageSelector(context),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    String selectedLanguageCode = localeProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(context.tr('select_language')),
            backgroundColor: Colors.white,
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageOption(
                    context,
                    code: 'vi',
                    name: context.tr('vietnamese'),
                    isSelected: selectedLanguageCode == 'vi',
                    onTap: () {
                      setState(() {
                        selectedLanguageCode = 'vi';
                      });
                    },
                  ),
                  _buildLanguageOption(
                    context,
                    code: 'en',
                    name: context.tr('english'),
                    isSelected: selectedLanguageCode == 'en',
                    onTap: () {
                      setState(() {
                        selectedLanguageCode = 'en';
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedLanguageCode != localeProvider.locale.languageCode) {
                    Locale newLocale = Locale(
                      selectedLanguageCode,
                      selectedLanguageCode == 'vi' ? 'VN' : 'US',
                    );
                    localeProvider.setLocale(newLocale);

                    Future.delayed(Duration(milliseconds: 100), () {
                      final expenseViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
                      expenseViewModel.setContext(context);
                      expenseViewModel.refreshCategoryLabels();
                    });

                    Navigator.pop(context);

                    MessageUtils.showSuccessMessage(
                      context,
                      context.tr('language_changed', [
                        selectedLanguageCode == 'vi'
                            ? context.tr('vietnamese')
                            : context.tr('english')
                      ]),
                    );
                  } else {
                    Navigator.pop(context);
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

  Widget _buildLanguageOption(
      BuildContext context, {
        required String code,
        required String name,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('assets/flags/$code.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: onTap,
      selected: isSelected,
    );
  }
}