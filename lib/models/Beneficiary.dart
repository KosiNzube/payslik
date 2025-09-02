class Beneficiary {
  final String id;
  final String beneficiaryName;
  final String accountNumber;
  final String bankId;
  final String bankName;
  final String nickname;
  final String telephone;

  Beneficiary({
    required this.id,
    required this.beneficiaryName,
    required this.accountNumber,
    required this.bankId,
    required this.bankName,
    required this.nickname,
    required this.telephone,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] ?? '',
      beneficiaryName: json['beneficiary_name']
          ?? json['nickname']
          ?? json['beneficiary_identifier']
          ?? '',
      accountNumber: json['beneficiary_identifier'] ?? '',
      bankId: json['bank_id'] ?? '',
      bankName: json['bank_name'] ?? '',
      nickname: json['nickname'] ?? '',
      telephone: json['owner']?['telephone']
          ?? json['beneficiary_identifier']
          ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beneficiary_name': beneficiaryName,
      'account_number': accountNumber,
      'bank_id': bankId,
      'bank_name': bankName,
      'nickname': nickname,
      'telephone': telephone,
    };
  }
}
