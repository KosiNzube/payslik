import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/WalletController.dart';
import 'package:gobeller/controller/create_wallet_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../success/DASHBOARD_Y.dart';
import 'widget/wallet_list.dart';

class CryptoWalletPage extends StatefulWidget {

  final bool menu;

  const CryptoWalletPage({super.key, required this.menu});

  @override
  _CryptoWalletPageState createState() => _CryptoWalletPageState();
}

class _CryptoWalletPageState extends State<CryptoWalletPage> {
  List<Map<String, dynamic>> wallets = [];
  bool isLoading = true;
  bool hasError = false;

  List<dynamic> currencies = [];
  bool isCurrencyLoading = true;
  String selectedCurrencyId = '';

  List<Map<String, dynamic>> walletTypes = [];
  bool isWalletTypeLoading = true;
  String selectedWalletTypeId = '';

  List<Map<String, dynamic>> banks = [];
  bool isBanksLoading = true;
  String selectedBankId = '';

  String selectedAccountType = 'virtual-account';
  bool _canCreateCryptoWallet = false;

  bool isCreatingWallet = false;
  bool isWalletsLoading = false;

  Future<void> _checkFxWalletCreationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        setState(() {
          _canCreateCryptoWallet = orgData['data']?['customized_app_displayable_menu_items']?['can-create-crypto-wallet'] ?? false;

        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _canCreateCryptoWallet = false;

        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePage();

    _checkFxWalletCreationEnabled();
  }

  Future<void> _initializePage() async {
    try {
      await Future.wait([
        _loadCryptoCurrencies(),
        _loadWalletTypes()



      ]);
      hasError = false;
    } catch (e) {
      hasError = true;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }




  Future<void> _loadCryptoCurrencies() async {
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);

      final response = await CurrencyController.fetchCryptoCurrencies();
      if (response != null) {
        setState(() => currencies = response);
      }
    } catch (e) {
      debugPrint("❌ Failed to load crypto currencies: $e");
    } finally {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }



  Future<void> _refreshWallets(BuildContext context) async {
    try {
      // Access the GeneralWalletProvider and call refreshCryptoWallets
      await Provider.of<GeneralWalletProvider>(context, listen: false)
          .refreshCryptoWallets();
    } catch (e) {
      // Handle any errors during refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh crypto wallets: $e'),
        ),
      );
    }
  }
  Future<void> _loadWalletTypes() async {
    try {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = true);

      final response = await CurrencyController.fetchWalletTypes();
      if (!mounted) return;

      setState(() {
        walletTypes = response ?? [];
        isWalletTypeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = false);
    }
  }





  void _createNewCryptoWallet(BuildContext context) {

    if (isCurrencyLoading) {
      snacklen("Please wait, loading options...");

      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !isCreatingWallet,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Create New Crypto Wallet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDropdown(
                          label: "Account Type",
                          items: const [
                            DropdownMenuItem(
                              value: "crypto-account",
                              child: Text("Crypto Account"),
                            ),
                          ],
                          value: "crypto-account",
                          onChanged: null,
                        ),
                        const SizedBox(height: 20),
                        isCurrencyLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdown(
                          label: "Currency",
                          items: currencies.map<DropdownMenuItem<String>>((currency) {
                            return DropdownMenuItem<String>(
                              value: currency["id"],
                              child: Text(
                                currency["name"],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: selectedCurrencyId.isNotEmpty ? selectedCurrencyId : null,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedCurrencyId = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        if (selectedCurrencyId.isNotEmpty)
                          _buildDropdown(
                            label: "Network",
                            items: _getNetworkOptions(selectedCurrencyId),
                            value: selectedCurrencyNetwork.isNotEmpty ? selectedCurrencyNetwork : null,
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedCurrencyNetwork = value!;
                              });
                            },
                          ),
                        const SizedBox(height: 20),
                        isWalletTypeLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdown(
                          label: "Wallet Type",
                          items: walletTypes.map<DropdownMenuItem<String>>((walletType) {
                            return DropdownMenuItem<String>(
                              value: walletType["id"],
                              child: Text(
                                walletType["name"],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: selectedWalletTypeId.isNotEmpty ? selectedWalletTypeId : null,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedWalletTypeId = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: isCreatingWallet
                          ? null
                          : () async {
                        if (selectedCurrencyId.isEmpty || selectedCurrencyNetwork.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select currency and network.")),
                          );
                          return;
                        }

                        final requestBody = {
                          "account_type": "crypto-account",
                          "wallet_type_id": selectedWalletTypeId,
                          "currency_id": selectedCurrencyId,
                          "currency_network": selectedCurrencyNetwork,
                        };

                        setStateDialog(() => isCreatingWallet = true);

                        try {
                          final result = await CurrencyController.createWallet(requestBody);

                          if (result["status"] == "success" || result["status"] == true) {
                            await _refreshWallets(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Crypto wallet created successfully.")),
                            );

                            setState(() {
                              selectedCurrencyId = '';
                              selectedCurrencyNetwork = '';
                            });

                            Navigator.of(context).pop();
                          } else {
                            final errorMsg = result["message"] ?? "Something went wrong.";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          }
                        } catch (e) {
                          final errorMsg = e.toString().replaceFirst("Exception: ", "");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        } finally {
                          setStateDialog(() => isCreatingWallet = false);
                        }
                      },
                      child:  Text("Create Crypto Wallet",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
                if (isCreatingWallet)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<DropdownMenuItem<String>> items,
    String? value,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      value: value,
      onChanged: onChanged,
    );
  }

// Helper method to get network options based on selected currency
  List<DropdownMenuItem<String>> _getNetworkOptions(String currencyId) {
    switch (currencyId) {
      case "7ac8db6f-f553-4174-8258-ec6360a6a372": // USDT
        return const [
          DropdownMenuItem<String>(
            value: "TRC20",
            child: Text("TRC20 (Tron)"),
          ),
          DropdownMenuItem<String>(
            value: "ERC20",
            child: Text("ERC20 (Ethereum)"),
          ),
        ];
      case "b8fe73e0-b8bd-45d0-8c39-f72b854757b8": // USDC
        return const [
          DropdownMenuItem<String>(
            value: "POL",
            child: Text("POL (Polygon)"),
          ),
        ];
      default:
        return [];
    }
  }


  String selectedCurrencyNetwork = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.menu==true? AppBar(
        title: Text("Crypto"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ):null,



      body: Column(
        children: [
          Expanded(
            child: CryptoWalletList(

            ),
          ),
          if (_canCreateCryptoWallet)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _createNewCryptoWallet(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Create New Crypto Wallet",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

