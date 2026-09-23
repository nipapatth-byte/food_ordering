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
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

        case 'invalid-email':
          return 'รูปแบบอีเมลไม่ถูกต้อง';

        case 'user-disabled':
          return 'บัญชีนี้ถูกปิดใช้งาน';

        case 'too-many-requests':
          return 'มีการพยายามเข้าสู่ระบบหลายครั้ง กรุณาลองใหม่ภายหลัง';

        case 'network-request-failed':
          return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';

        default:
          return 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอีเมลและรหัสผ่าน';
      }
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

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'รูปแบบอีเมลไม่ถูกต้อง';

        case 'user-not-found':
          // ใช้ข้อความกลาง ไม่เปิดเผยว่าอีเมลมีบัญชีหรือไม่
          return null;

        case 'too-many-requests':
          return 'มีการขอรีเซ็ตรหัสผ่านหลายครั้ง กรุณาลองใหม่ภายหลัง';

        case 'network-request-failed':
          return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';

        default:
          return 'ไม่สามารถส่งอีเมลรีเซ็ตรหัสผ่านได้';
      }
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
