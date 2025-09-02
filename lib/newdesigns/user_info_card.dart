

/*
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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
                backgroundColor: Colors.purple,
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

     code=widget.wallet_currency;
     symbol=widget.symbol;
     balance=widget.balance;



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





  @override
  Widget build(BuildContext context) {


    String formattedBalance = NumberFormat("#,##0.00")
        .format(double.tryParse(balance) ?? 0.00);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
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
                color: const Color(0xFF7A36D4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    code,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  code=="---"?Container():Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Flag.fromCode(
                      code =="NGN"?FlagsCode.NG: code=="GBP"?FlagsCode.GB:code=="USD"?FlagsCode.US:code=="CAD"?FlagsCode.CA:FlagsCode.GP,
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
                style: const TextStyle(  fontSize: 16,
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
            style: const TextStyle(   fontSize: 28,
              fontWeight: FontWeight.bold,),
          ),


          const SizedBox(height: 12),


          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {

                showBankDetails(context, widget.bankName, widget.bankCode, widget.accountNumber);


              },
              icon: const Icon(Icons.info, color: Colors.deepPurple),
              label: const Text(
                'Bank Details',
                style: TextStyle(color: Colors.deepPurple),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }
}


 */