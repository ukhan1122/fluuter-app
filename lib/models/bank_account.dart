// lib/models/bank_account.dart

class BankAccount {
  final int? id;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String? routingNumber;
  final String? iban;
  final String? swiftCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankAccount({
    this.id,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    this.routingNumber,
    this.iban,
    this.swiftCode,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      routingNumber: json['routing_number'],
      iban: json['iban'],
      swiftCode: json['swift_code'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'iban': iban,
      'swift_code': swiftCode,
    };
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return '****';
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}