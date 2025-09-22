import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/WalletController.dart';
import 'package:gobeller/controller/create_wallet_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../controller/WalletTransactionController.dart';
import '../../../controller/profileControllers.dart';
import '../../success/DASHBOARD_Y.dart';
import 'widget/wallet_list.dart';

class FXWalletPage extends StatefulWidget {
  const FXWalletPage({super.key});

  @override
  _FXWalletPageState createState() => _FXWalletPageState();
}

class _FXWalletPageState extends State<FXWalletPage> {
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
  bool _canCreateFxWallet = false;

  Future<void> _checkFxWalletCreationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        setState(() {
          _canCreateFxWallet = orgData['data']?['customized_app_displayable_menu_items']?['can-create-fx-wallet'] ?? false;
          _canCreateCryptoWallet =  orgData['data']?['customized_app_displayable_menu_items']?['display-crypto-exchange-menu'] ?? false;

        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _canCreateFxWallet = false;
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
        _loadCurrencies(),
        _loadWalletTypes(),
        _loadBanks(),
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




// Add a refresh method for manual refresh
  Future<void> _refreshWallets() async {

    final profile = await ProfileController.fetchUserProfile();

    if (profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GeneralWalletProvider>().loadWallets();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<WalletTransactionController>(context, listen: false)
            .fetchWalletTransactions(refresh: false);
      });
    }

    setState(() {
    });
  }


  Future<void> _loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);

      final cachedCurrencies = prefs.getString('cachedCurrencies');
      if (cachedCurrencies != null) {
        final decoded = jsonDecode(cachedCurrencies);
        if (decoded is List) {
          setState(() => currencies = decoded);
        }
      }

      final response = await CurrencyController.fetchCurrencies();
      if (response != null) {
        setState(() => currencies = response);
        prefs.setString('cachedCurrencies', jsonEncode(response));
      }
    } catch (e) {
      debugPrint("Failed to load currencies: $e");
    } finally {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }

  Future<void> _loadBanks() async {
    try {
      if (!mounted) return;
      setState(() => isBanksLoading = true);

      final response = await CurrencyController.fetchBanks();
      if (!mounted) return;

      setState(() {
        banks = response ?? [];
        isBanksLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isBanksLoading = false);
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



  void _createNewWallet(BuildContext context) {
    if (isCurrencyLoading || isWalletTypeLoading || isBanksLoading) {

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
                    "Create New Wallet",
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
                              value: "virtual-account",
                              child: Text("Virtual Account"),
                            ),
                          ],
                          value: "virtual-account",
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
                        const SizedBox(height: 20),

                        if (selectedAccountType == 'virtual-account')
                          isBanksLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildDropdown(
                            label: "Bank",
                            items: banks.isNotEmpty
                                ? banks.map<DropdownMenuItem<String>>((bank) {
                              return DropdownMenuItem<String>(
                                value: bank["id"],
                                child: Text(
                                  bank["name"],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList()
                                : const [
                              DropdownMenuItem<String>(
                                value: '',
                                child: Text("No banks available"),
                              ),
                            ],
                            value: banks.isNotEmpty
                                ? (selectedBankId.isNotEmpty ? selectedBankId : null)
                                : '',
                            onChanged: banks.isNotEmpty
                                ? (value) {
                              setStateDialog(() {
                                selectedBankId = value!;
                              });
                            }
                                : null,
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
                        if (selectedCurrencyId.isEmpty ||
                            selectedWalletTypeId.isEmpty ||
                            (selectedAccountType == 'virtual-account' &&
                                selectedBankId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields.")),
                          );
                          return;
                        }

                        final requestBody = {
                          "account_type": selectedAccountType,
                          if (selectedAccountType == 'virtual-account') "bank_id": selectedBankId,
                          "wallet_type_id": selectedWalletTypeId,
                          "currency_id": selectedCurrencyId,
                        };

                        setStateDialog(() => isCreatingWallet = true);

                        try {
                          final result = await CurrencyController.createWallet(requestBody);

                          if (result["status"] == "success" || result["status"] == true) {
                            await _refreshWallets();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Wallet created successfully.")),
                            );

                            setState(() {
                              selectedCurrencyId = '';
                              selectedWalletTypeId = '';
                              selectedBankId = '';
                              selectedAccountType = 'internal-account';
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
                      child:  Text("Create Wallet",style: TextStyle(color: Colors.white),),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar:_canCreateCryptoWallet?null: AppBar(
        title: const Text("Wallets"),
        automaticallyImplyLeading: false, // This removes the back button

        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_2_circlepath),
            onPressed:(){  _refreshWallets();}
          ),
        ],
      ),


      body: Column(
        children: [
          Expanded(
            child: WalletList(

            ),
          ),
          if (_canCreateFxWallet)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _createNewWallet(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Create New Wallet",
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