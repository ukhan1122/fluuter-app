// lib/models/user_model.dart

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime joinDate;
  final int totalSales;
  final double totalEarnings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.totalSales,
    required this.totalEarnings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? json['first_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['phone_number'] ?? '',
      joinDate: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      totalSales: json['total_sales'] ?? json['products_count'] ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get initials {
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }
}