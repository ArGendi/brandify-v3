class AppUser {
  final String id;
  final String username;
  final String? parentId; // UID of the creator
  final List<String> privileges; // e.g. ['view_sales', 'add_product', ...]
  final String? password;
  final String? phone;

  AppUser({
    required this.id,
    required this.username,
    this.parentId,
    required this.privileges,
    this.password,
    this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      id: id,
      username: json['username'] ?? '',
      parentId: json['parentId'],
      privileges: List<String>.from(json['privileges'] ?? []),
      password: json['password'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'parentId': parentId,
      'privileges': privileges,
      'password': password,
      'phone': phone,
    };
  }
} 