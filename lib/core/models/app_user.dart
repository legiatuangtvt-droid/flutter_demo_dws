class AppUser {
  final String id;
  final String name;
  final String email;
  final String storeId;
  final String roleId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.storeId,
    required this.roleId,
  });

  // Một factory constructor để tạo AppUser từ dữ liệu Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      storeId: data['storeId'] ?? '',
      roleId: data['roleId'] ?? '',
    );
  }
}
