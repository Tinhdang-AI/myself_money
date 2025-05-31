import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/message_utils.dart';
import '/localization/app_localizations_extension.dart'; // Import localization extension

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : (isConfirmPassword ? _obscureConfirmPassword : false),
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
            : (isConfirmPassword
            ? IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        )
            : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return Scaffold(
        backgroundColor: Colors.orange.shade100,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (authViewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MessageUtils.showErrorMessage(context, authViewModel.errorMessage!);
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 45,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    context.tr('signup_title'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    context.tr('signup_prompt'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  _buildTextField(
                    hintText: context.tr('name'),
                    controller: nameController,
                    prefixIcon: Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    hintText: context.tr('email'),
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    hintText: context.tr('password'),
                    controller: passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    hintText: context.tr('confirm_password'),
                    controller: confirmPasswordController,
                    isConfirmPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _signUp(context, authViewModel),
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
                        context.tr('signup'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white70, thickness: 1)),
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
                      Expanded(child: Divider(color: Colors.white70, thickness: 1)),
                    ],
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _signInWithGoogle(context, authViewModel),
                      icon: Image.asset('assets/google_icon.png', width: 24, height: 24),
                      label: Text(
                        context.tr('signup_with_google'),
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
                  Text.rich(
                    TextSpan(
                      text: context.tr('have_account'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: context.tr('login'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/login');
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

  Future<void> _signUp(BuildContext context, AuthViewModel authViewModel) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      MessageUtils.showErrorMessage(context, context.tr('enter_all_info'));
      return;
    }

    if (!EmailValidator.validate(email)) {
      MessageUtils.showErrorMessage(context, context.tr('invalid_email'));
      return;
    }

    if (password != confirmPassword) {
      MessageUtils.showErrorMessage(context, context.tr('passwords_not_match'));
      return;
    }

    if (password.length < 6) {
      MessageUtils.showErrorMessage(context, context.tr('password_requirements'));
      return;
    }

    bool success = await authViewModel.signUpWithEmail(name, email, password);

    if (success) {
      MessageUtils.showAlertDialog(
        context: context,
        title: context.tr('signup_success'),
        message: context.tr('signup_success_message'),
        onOk: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context, AuthViewModel authViewModel) async {
    bool success = await authViewModel.signInWithGoogle();
    if (success) {
      MessageUtils.showSuccessMessage(context, context.tr('login_success'));
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/expense');
      }
    }
  }
}
