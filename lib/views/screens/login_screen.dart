import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/message_utils.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '/localization/app_localizations_extension.dart'; // Import localization extension

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Custom text field with consistent styling
  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.deepOrange, width: 2),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the AuthViewModel using Provider
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Show loading indicator if authentication is in progress
    if (authViewModel.isLoading) {
      return Scaffold(
        backgroundColor: Colors.orange.shade100,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    // Check for error message from view model and display it
    if (authViewModel.errorMessage != null) {
      // Use post-frame callback to show the error message after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MessageUtils.showErrorMessage(context, authViewModel.errorMessage!);
        // Clear the error message after showing it
        Future.delayed(Duration(milliseconds: 100), () {
          // The error will be cleared on the next frame
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                _showLanguageSelector(context);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.language, color: Colors.white, size: 24),
                  SizedBox(height: 2),
                  Text(
                    context.tr('language'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo_icon.png',
                    width: 100,
                    height: 100,
                  ),

                  SizedBox(height: 10),

                  // Welcome text
                  Text(
                    context.tr('welcome_back'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Text(
                    context.tr('login_prompt'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Email input field
                  _buildTextField(
                    hintText: context.tr('email'),
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  SizedBox(height: 16),

                  // Password input field
                  _buildTextField(
                    hintText: context.tr('password'),
                    controller: passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),

                  SizedBox(height: 12),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: Text(
                        context.tr('forgot_password'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _login(context, authViewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepOrange,
                        elevation: 5,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        context.tr('login'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          context.tr('or'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _signInWithGoogle(context, authViewModel),
                      icon: Image.asset(
                          'assets/google_icon.png', width: 24, height: 24),
                      label: Text(
                        context.tr('login_with_google'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        elevation: 5,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // Sign up link
                  Text.rich(
                    TextSpan(
                      text: context.tr('no_account'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: context.tr('signup'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/signup');
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Email and password login
  Future<void> _login(BuildContext context, AuthViewModel authViewModel) async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      MessageUtils.showErrorMessage(context, context.tr('enter_email_password'));
      return;
    }

    bool success = await authViewModel.signInWithEmail(email, password);

    if (success) {
      // Show success message before navigation
      MessageUtils.showSuccessMessage(context, context.tr('login_success'));

      // Slight delay to allow the message to be seen
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/expense');
      }
    }
  }

  // Google sign in
  Future<void> _signInWithGoogle(BuildContext context, AuthViewModel authViewModel) async {
    bool success = await authViewModel.signInWithGoogle();

    if (success) {
      // Show success message before navigation
      MessageUtils.showSuccessMessage(context, context.tr('login_success'));

      // Slight delay to allow the message to be seen
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/expense');
      }
    }
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
            content: Column(
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