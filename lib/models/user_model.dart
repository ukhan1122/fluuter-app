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
}