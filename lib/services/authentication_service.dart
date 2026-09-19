import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// รับผิดชอบแค่การคุยกับ Firebase Auth + สร้าง user doc ใน Firestore เท่านั้น
// ไม่ยุ่งกับ UI เลย
class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // สำเร็จ
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'เข้าสู่ระบบไม่สำเร็จ';
    }
  }

  Future<String?> register(
    String email,
    String password,
    String role, {
    String displayName = '',
    String phone = '',
    String address = '',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // สร้าง document เก็บ role ไว้ที่ users/{uid}
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
        'displayName': displayName,
        'phone': phone,
        'address': address,
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'สมัครสมาชิกไม่สำเร็จ';
    }
  }

  Future<void> logout() async => await _auth.signOut();

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  // ดึง role ของ user จาก Firestore
  Future<String> fetchUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'customer';
  }

  Future<Map<String, dynamic>> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? <String, dynamic>{};
  }
}
