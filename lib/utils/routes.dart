import 'package:flutter/material.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/pages/registration/OtpVerificationPage.dart';
import 'package:gobeller/pages/registration/registration.dart';
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:gobeller/pages/success/transaction_history.dart';
import 'package:gobeller/pages/welcome/welcome_page.dart';
import 'package:gobeller/pages/profile/profile_page.dart';
import 'package:gobeller/pages/wallet/wallet_page.dart';
import 'package:gobeller/pages/cards/virtual_card_page.dart';
import 'package:gobeller/pages/cards/card_details_page.dart';
import 'package:gobeller/pages/quick_action/airtime.dart';
import 'package:gobeller/pages/quick_action/data_purchase_page.dart';
import 'package:gobeller/pages/quick_action/cable_tv_page.dart';
import 'package:gobeller/pages/quick_action/electric_meter_page.dart';
import 'package:gobeller/pages/quick_action/wallet_to_wallet.dart';
import 'package:gobeller/pages/quick_action/wallet_to_bank.dart';

import 'package:gobeller/pages/loan/loan.dart';
import 'package:gobeller/pages/loan/loan_form.dart';
import 'package:gobeller/pages/loan/loan_summary.dart';
import 'package:gobeller/pages/fixed_deposit/fixed_deposit.dart';
import 'package:gobeller/pages/fixed_deposit/fixed_form.dart';
import 'package:gobeller/pages/investment/investment_screen.dart';

import 'package:gobeller/pages/coming_soon/corp_soon.dart';
import 'package:gobeller/pages/coming_soon/fx_soon.dart';
import 'package:gobeller/pages/coming_soon/loan_soon.dart';

import 'package:gobeller/pages/corporate_account/corporate_registration.dart';
import 'package:gobeller/pages/corporate_account/account_details_page.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';
import 'package:gobeller/pages/borrowers/borrowers.dart';
import 'package:gobeller/pages/success_screens/registration_success_screen/regSuccess.dart';
import 'package:gobeller/pages/success_screens/quick_menu/airtime_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/data_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/electricity_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/wallet_to_bank_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/wallet_to_wallet_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/cable_result.dart';
import 'package:gobeller/pages/success/more_menu_page.dart';
import 'package:gobeller/target_savings/TargetSavingsScreen.dart';

import '../pages/quick_action/swap_page.dart';
import '../pages/success_screens/quick_menu/mobile_money_receive_success.dart';
import '../pages/wallet/screens/crypto_wallet_page.dart';

class Routes {
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String virtualCard = '/virtualCard';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String airtime = '/airtime';
  static const String data_purchase = '/data_purchase';
  static const String cable_tv = '/cable-tv';
  static const String electric = '/electric';
  static const String transfer = '/transfer';
  static const String bank_transfer = '/bank_transfer';
  static const String transfer_result = '/transfer_result';
  static const String reg_success = '/reg_success';
  static const String airtime_result = '/airtime-result';
  static const String data_result = '/data_result';
  static const String electricity_result = '/electricity_result';
  static const String bank_result = '/bank_result';
  static const String cable_result = '/cable_result';
  static const String card_details = '/card_details';
  static const String coming_soon = '/coming_soon';
  static const String fx_soon = '/fx_soon';
  static const String loan_soon = '/loan_soon';
  static const String corporate = '/corporate';
  static const String corporate_account = '/corporate_account';
  static const String loan = '/loan';
  static const String loan_form = '/loan_form';
  static const String fixed = '/fixed';
  static const String fixed_form = '/fixed_form';
  static const String loan_summary = '/loan_summary';
  static const String borrow = '/borrow';
  static const String more_menu = '/more_menu';
  static const String investment = '/investment';
  static const String target_savings = '/target_savings';
  static const String crypto = '/crypto';
  static const String swap = '/swap';

  static const String mobile_money_result = '/mobile_money_result';

  static const String otp = '/otp';






  static Map<String, Widget Function(BuildContext)> routes = {
    initial: (context) => const WelcomePage(),
    login: (context) => const LoginPage(),
    register: (context) => RegistrationPage(),
    dashboard: (context) => const BaseLayout(initialIndex: 0),
    history: (context) => const TransactionHistoryPage(),
    profile: (context) => const ProfilePage(),
    wallet: (context) => const WalletPage(),
    swap: (context) => const SwapPage(),


    virtualCard: (context) => const VirtualCardPage(),
    airtime: (context) => const BuyAirtimePage(),
    data_purchase: (context) => const DataPurchasePage(),
    cable_tv: (context) => const CableTVPage(),
    electric: (context) => const ElectricityPaymentPage(),
    transfer: (context) => const WalletToWalletTransferPage(),
    bank_transfer: (context) => const WalletToBankTransferPage(),
    transfer_result: (context) => const TransferResultPage(),
    reg_success: (context) => const RegistrationSuccessPage(),
    airtime_result: (context) => const AirtimeResultPage(),
    data_result: (context) => const DataResultPage(),
    electricity_result: (context) => const ElectricityResultPage(),
    bank_result: (context) => const WalletTransferResultPage(),
    mobile_money_result: (context) => const MobileMoneyReceiveSuccessPage(),

    cable_result: (context) => const CableTVResultPage(),
    coming_soon: (context) => const UpgradeScreen(),
    loan_soon: (context) => const LoanUpgradeScreen(),
    fx_soon: (context) => const FxUpgradeScreen(),
    corporate: (context) => const CorporateAccountRegistrationPage(),
    corporate_account: (context) => const AccountDetailsPage(),
    loan: (context) => const LoanPage(),
    borrow: (context) => const PropertyListPage(),
    loan_summary: (context) => LoanSummaryPage(),
    fixed: (context) => FixedDepositScreen(),
    investment: (context) => InvestmentScreen(),
    target_savings: (context) => TargetSavingsScreen(),
    crypto: (context) => CryptoWalletPage(menu:true),

    fixed_form: (context) => CreatePlanPage(),
    card_details: (context) {
      final card = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CardDetailsPage(card: card);
    },
    more_menu: (context) => const MoreMenuPage(),
  };
}

