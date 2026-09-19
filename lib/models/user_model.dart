class UserModel {
  final String uid;
  final String email;
  final String role; // "customer" | "seller"

  UserModel({required this.uid, required this.email, required this.role});

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role};
  }
}
