/// A logged-in tenant user.
class TenantUser {
  final int id;
  final String name;
  final String email;
  final String role; // tenant_admin | manager | member

  TenantUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory TenantUser.fromJson(Map<String, dynamic> json) => TenantUser(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        role: (json['role'] ?? 'member') as String,
      );
}
