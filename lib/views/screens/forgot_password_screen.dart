import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/message_utils.dart';
import '/localization/app_localizations_extension.dart'; // Import localization extension

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();

    // Client-side validation
    if (email.isEmpty) {
      MessageUtils.showErrorMessage(context, context.tr('required_field', ['email']));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!EmailValidator.validate(email)) {
      MessageUtils.showErrorMessage(context, context.tr('invalid_email'));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get access to auth view model
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Use view model to reset password
      bool success = await authViewModel.resetPassword(email);

      if (success) {
        // Show success message and navigate
        _showSuccessAndNavigate(context.tr('reset_password_message'));
      } else if (authViewModel.errorMessage != null) {
        // Display error from view model
        MessageUtils.showErrorMessage(context, authViewModel.errorMessage!);
      }
    } catch (e) {
      MessageUtils.showErrorMessage(context, "${context.tr('error')}: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessAndNavigate(String message) {
    MessageUtils.showAlertDialog(
        context: context,
        title: context.tr('success'),
        message: message,
        okLabel: "OK",
        onOk: () {
          Navigator.pushReplacementNamed(context, '/login');
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
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
                  SizedBox(height: 10),

                  // Lock icon
                  Container(
                    width: 100,
                    height: 100,
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
                      Icons.lock_reset,
                      size: 55,
                      color: Colors.deepOrange,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    context.tr('reset_password_title'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    context.tr('reset_password_prompt'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Email field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: context.tr('email'),
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
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Send email button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepOrange,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 5,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        context.tr('send_email'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // Back to login link
                  Text.rich(
                    TextSpan(
                      text: context.tr('back_to_login'),
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
                              Navigator.pop(context);
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}