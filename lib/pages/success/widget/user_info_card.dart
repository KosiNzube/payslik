import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'bank_details.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/themes/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../controller/user_controller.dart';
import '../../../utils/routes.dart';
import 'package:dio/dio.dart';

class UserInfoCard extends StatefulWidget {
  final String username;
  final String accountNumber;
  final String balance;
  final String bankCode;


  final String wallet_number;
  final String wallet_currency;
  final String symbol;


  final String bankName;
  final bool hasWallet;

  const UserInfoCard({
    super.key,
    required this.username,
    required this.accountNumber,
    required this.balance,
    required this.bankName,
    required this.hasWallet, required this.bankCode, required this.wallet_number, required this.wallet_currency, required this.symbol,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  bool _isBalanceHidden = true;
  Color? _primaryColor;
  Color? _secondaryColor;

  final _secureStorage = FlutterSecureStorage();

  String code="---";
  String balance="---";
  String symbol="---";


  // Fetch currencies from the API
  final List<Map<String, dynamic>> currencies = [
    {"name": "Nigerian Naira", "code": "NGN", "symbol": "₦"},
    {"name": "British Pound Sterling", "code": "GBP", "symbol": "£"},
    {"name": "Euro", "code": "EUR", "symbol": "€"},
    {"name": "United States Dollar", "code": "USD", "symbol": "\$"},
    {"name": "Canadian Dollar", "code": "CAD", "symbol": "C\$"},
    {"name": "Bitcoin", "code": "BTC", "symbol": "₿"},
    {"name": "Ethereum", "code": "ETH", "symbol": "Ξ"},
  ];


  void showCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            final currency = currencies[index];
            return ListTile(
              onTap: () async {


                SmartDialog.showLoading(msg: "Please wait");

                await fetchExchangeRate(widget.wallet_currency,widget.balance,currency['code']);

                SmartDialog.dismiss();

                setState(() {
                  code=currency['code'];
                  symbol=currency['symbol'];
                });


                Navigator.pop(context);

              },

              leading: CircleAvatar(
                backgroundColor: kPrimaryColor,
                child: Text(currency['symbol'],style: TextStyle(color: Colors.white),),
              ),
              title: Text(currency['name']),
              subtitle: Text(currency['code']),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();

    code=widget.bankCode;
    symbol=widget.symbol;
    balance=widget.balance;



  }

  Future<void> fetchExchangeRate(String baseCurrency, String exchangeAmount, String quoteCurrency) async {
    Dio dio = Dio();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('auth_token');
    final String? appId = prefs.getString('appId');

    // Set the headers
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'AppID': appId
    };

    // Prepare the data for the request
    var data = {
      "base_currency": baseCurrency,
      "exchange_amount": exchangeAmount,
      "quote_currency": quoteCurrency,
    };

    try {
      // Make the POST request
      Response response = await dio.post(
        'https://app.gobeller.com/api/v1/currencies/exchange/rate',
        data: data,
      );

      print(response.data);


      if (response.data['status'] == true && response.data['data'] != null) {
        var quoteAmount = response.data['data']['quote_amount'];

        setState(() {
          balance=quoteAmount.toString();
        });


      } else {
        print('API returned success=false or missing data: ${response.data}');
        return null;
      }
    } catch (e) {
      // Handle any errors
      print('Error: $e');
    }
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  Future<bool> _isTokenValid() async {
    String? token = await UserController.getToken();
    debugPrint("Auth Token: $token"); // 👈 Print token
    return token != null && token.isNotEmpty;
  }

  bool flagger(){
    if(code=="NGN"||code=="GBP"||code=="EUR"||code=="USD"||code=="CAD"){
      return true;
    }else{
      return false;
    }

  }




  @override
  Widget build(BuildContext context) {


    String formattedBalance = NumberFormat("#,##0.00")
        .format(double.tryParse(balance) ?? 0.00);

    return  Padding(
      padding: const EdgeInsets.all(17.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primaryColor!.withOpacity(.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [



            InkWell(
              onTap: (){
                showCurrencyBottomSheet(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.symbol,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    code=="---"?Container():Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Flag.fromCode(
                        code =="NGN"?FlagsCode.NG: code=="GBP"?FlagsCode.GB:code=="USD"?FlagsCode.US:code=="CAD"?FlagsCode.CA:FlagsCode.NG,
                        height: 24,
                        width: 24,
                        borderRadius: 12,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),



            const SizedBox(height: 16),


            Row(
              children: [
                Text(
                  "Balance",
                  style:  GoogleFonts.poppins(  fontSize: 16,
                    color: Colors.black54,),
                ),
                SizedBox(width: 5,),
                IconButton(
                  icon: Icon(
                    _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                ),
              ],
            ),

            Text(
              _isBalanceHidden ? "******" : symbol+"$formattedBalance",
              style:  GoogleFonts.nunito(   fontSize: 28,
                fontWeight: FontWeight.bold,),
            ),


            const SizedBox(height: 12),


            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {

                  showBankDetails(context, widget.bankName, widget.bankCode, widget.accountNumber);


                },
                icon:  Icon(Icons.info, color: _primaryColor),
                label:  Text(
                  'Bank Details',
                  style: TextStyle(color: _primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.transparent),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),


            /*
            Text(
              "Hello, ${widget.username} 👋",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            if (!widget.hasWallet)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text("Create Wallet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryColor ?? Colors.deepPurple,
                  ),
                  onPressed: () async {
                    bool isValid = await _isTokenValid();
                    if (isValid) {
                      Navigator.pushNamed(context, Routes.wallet);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Session expired. Please log in again."),
                        ),
                      );
                      Navigator.pushReplacementNamed(context, Routes.dashboard);
                    }
                  },
                ),
              )
            else ...[
              Row(
                children: [
                  Text(
                    "Acct: ${widget.accountNumber}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.accountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Account number copied!")),
                      );
                    },
                    child: const Icon(Icons.copy, color: Colors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.bankName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBalanceHidden ? "****" : "₦$formattedBalance",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(
                      _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isBalanceHidden = !_isBalanceHidden;
                      });
                    },
                  ),
                ],
              ),
            ],

             */
          ],
        ),
      ),
    );







  }
}
