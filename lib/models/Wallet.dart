class Wallet {
  final String id;
  final String walletNumber;
  final String walletName;
  final double balance;
  final String currencyCode;
  final String currencySymbol;

  Wallet({
    required this.id,
    required this.walletNumber,
    required this.walletName,
    required this.balance,
    required this.currencyCode,
    required this.currencySymbol,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      walletNumber: json['wallet_number'] ?? '',
      walletName: json['wallet_name'] ?? 'My Wallet',
      balance: (json['balance'] ?? 0.0).toDouble(),
      currencyCode: json['currency']?['code'] ?? '',
      currencySymbol: json['currency']?['symbol'] ?? '',
    );
  }
}