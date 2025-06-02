import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/currency_formatter.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/expense_viewmodel.dart';
import 'viewmodels/calendar_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/more_viewmodel.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/signup_screen.dart';
import 'views/screens/expense_screen.dart';
import 'views/screens/calendar_screen.dart';
import 'views/screens/report_screen.dart';
import 'views/screens/more_screen.dart';
import 'views/screens/search_screen.dart';
import 'views/screens/forgot_password_screen.dart';
import 'localization/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'dart:async';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize currency settings
  await initCurrency();

  // Load the saved locale before running the app
  final savedLocale = await AppLocalizations.getLocale();

  // Run the application with the saved locale
  runApp(FundyApp(initialLocale: savedLocale));
}

class FundyApp extends StatefulWidget {
  final Locale initialLocale;

  const FundyApp({Key? key, required this.initialLocale}) : super(key: key);

  @override
  _FundyAppState createState() => _FundyAppState();
}

class _FundyAppState extends State<FundyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => MoreViewModel()),
        ChangeNotifierProvider(
            create: (_) => LocaleProvider(initialLocale: widget.initialLocale)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Fundy',
            // Cấu hình đa ngôn ngữ
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              const AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ExitConfirmationWrapper(child: SplashScreen()),
            routes: {
              '/login': (context) => ExitConfirmationWrapper(child: LoginScreen()),
              '/signup': (context) => ExitConfirmationWrapper(child: SignupScreen()),
              '/expense': (context) => ExitConfirmationWrapper(child: ExpenseScreen()),
              '/calendar': (context) => ExitConfirmationWrapper(child: CalendarScreen()),
              '/report': (context) => ExitConfirmationWrapper(child: ReportScreen()),
              '/more': (context) => ExitConfirmationWrapper(child: MoreScreen()),
              '/search': (context) => SearchScreen(), // Không thêm xác nhận thoát cho màn hình tìm kiếm
              '/forgot_password': (context) => ExitConfirmationWrapper(child: ForgotPasswordScreen()),
            },
          );
        },
      ),
    );
  }
}
