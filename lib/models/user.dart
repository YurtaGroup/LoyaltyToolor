class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final DateTime? birthDate;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.birthDate,
  });
}
