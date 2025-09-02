import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'WalletProviders/General_Wallet_Provider.dart';
import 'controller/TargetSavingsController.dart';
import 'controller/WTCC.dart';
import 'controller/forgot_password_controller.dart';
import 'controller/investment_controller.dart';
import 'controller/swap_controller.dart';
import 'utils/routes.dart';
import 'provider/dark_mode_provider.dart';
import 'controller/airtime_controller.dart';
import 'controller/data_bundle_controller.dart';
import 'controller/cable_tv_controller.dart';
import 'controller/electricity_controller.dart';
import 'controller/WalletTransactionController.dart';
import 'controller/wallet_to_bank_controller.dart';
import 'controller/wallet_transfer_controller.dart';
import 'controller/registration_controller.dart';
import 'controller/organization_controller.dart';
import 'controller/cards_controller.dart';
import 'controller/loan_controller.dart';
import 'controller/CacVerificationController.dart';
import 'controller/property_controller.dart';
import 'controller/fixed_deposit_controller.dart';
import 'utils/navigator_key.dart';
import 'themes/color_schemes.dart';
import 'themes/input_decoration_theme.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;
  String? _appName;
  // String _appName = "SDDTIF THRIFT";  // Default app name

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final logoUrl = data['customized-app-logo-url'];
      final appName = data['customized-app-name'];  // Fetch short_name from the data

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _logoUrl = logoUrl;
        if (appName != null) {
          _appName = appName;  // Update the app name
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeProvider()..getDarkMode()),
        ChangeNotifierProvider(create: (_) => AirtimeController()), // Added
        ChangeNotifierProvider(create: (_) => DataBundleController()), // Added
        ChangeNotifierProvider(create: (_) => CableTVController()),
        ChangeNotifierProvider(create: (context) => ElectricityController()),
        ChangeNotifierProvider(create: (context) => WalletTransactionController()),
        ChangeNotifierProvider(create: (context) => WalletToBankTransferController()),
        ChangeNotifierProvider(create: (context) => WalletTransferController()),
        ChangeNotifierProvider(create: (context) => TargetSavingsController()),
        ChangeNotifierProvider(create: (context) => SwapController()),
        ChangeNotifierProvider(create: (context) => GeneralWalletProvider()),

        ChangeNotifierProvider(create: (context) => NinVerificationController()),
        ChangeNotifierProvider(create: (context) => No_KYC_Controller()),
        ChangeNotifierProvider(create: (_) => OrganizationController()),
        ChangeNotifierProvider(create: (context) => VirtualCardController()),
        ChangeNotifierProvider(create: (context) => CacVerificationController()),
        ChangeNotifierProvider(create: (context) => LoanController()),
        ChangeNotifierProvider(create: (context) => PropertyController()),
        ChangeNotifierProvider(create: (context) => FixedDepositController()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordController(),),
        ChangeNotifierProvider(create: (_) => WalletTransactionControllerCard(),),

        ChangeNotifierProvider(create: (_) => InvestmentController(),),
      ],
      child: Consumer<DarkModeProvider>(
        builder: (context, darkMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: _appName,  // Use dynamic app name
            navigatorKey: navigatorKey,
            navigatorObservers: [FlutterSmartDialog.observer],
            // here
            builder: FlutterSmartDialog.init(),
            themeMode: darkMode.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              textTheme:GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(bodyColor: CupertinoColors.darkBackgroundGray),

              appBarTheme: AppBarTheme(
                color: Colors.white,
                titleTextStyle: GoogleFonts.poppins(
                  color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              colorScheme: lightColorScheme,
              inputDecorationTheme: CustomInputDecorationTheme.inputDecorationTheme,
            ),
            darkTheme: ThemeData(
              textTheme:GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(bodyColor: CupertinoColors.white),

              appBarTheme: AppBarTheme(
                color: Colors.white,
                titleTextStyle: GoogleFonts.poppins(
                    color: Colors.black,

                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              colorScheme: darkColorScheme,
              inputDecorationTheme: CustomInputDecorationTheme.inputDecorationTheme,
            ),
            initialRoute: Routes.initial,
            routes: Routes.routes, // Use named routes
          );
        },
      ),
    );
  }
}