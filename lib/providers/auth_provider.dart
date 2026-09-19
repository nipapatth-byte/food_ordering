import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/authentication_service.dart';

// State ที่ UI ทั้งแอปฟังอยู่ (login/logout, role) ไม่คุยกับ Firebase ตรงๆ
// แต่เรียกผ่าน AuthenticationService เท่านั้น
class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();

  User? _user;
  String? _role; // "customer" | "seller" | null (ยังไม่ login)
  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _isLoading = false;
  // false จนกว่า Firebase จะเช็ค auth state ครั้งแรกเสร็จ (persistent login check)
  // ใช้บอก UI ว่าควรโชว์ splash อยู่ หรือพร้อมตัดสินใจแล้วว่าจะไปหน้าไหน
  bool _initialized = false;

  User? get user => _user;
  String? get role => _role;
  Map<String, dynamic> get profile => _profile;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  AuthProvider() {
    // authStateChanges() ของ Firebase จะจำ session ที่เคย login ไว้ให้อัตโนมัติ
    // (ปัดปิดแอป/รีสตาร์ทเครื่อง event แรกที่ยิงออกมาจะเป็น user เดิมที่เคย login ค้างไว้)
    // ที่นี่คือจุดเดียวที่ทั้งแอปเชื่อถือเพื่อตัดสินใจว่า login อยู่ไหม ไม่เช็คจากที่อื่น
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user != null) {
      _role = await _authService.fetchUserRole(user.uid);
      _profile = await _authService.fetchUserProfile(user.uid);
    } else {
      _role = null;
      _profile = <String, dynamic>{};
    }
    _initialized = true; // เช็ครอบแรกเสร็จแล้ว ไม่ว่าจะ login หรือไม่ก็ตาม
    notifyListeners(); // ทุก widget ที่ watch<AuthProvider>() จะ rebuild ทันที
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final error = await _authService.login(email, password);
    _isLoading = false;
    notifyListeners();
    return error;
  }

  Future<String?> register(
    String email,
    String password,
    String role, {
    String displayName = '',
    String phone = '',
    String address = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    final error = await _authService.register(
      email,
      password,
      role,
      displayName: displayName,
      phone: phone,
      address: address,
    );
    _isLoading = false;
    notifyListeners();
    return error;
  }

  Future<void> logout() async => await _authService.logout();

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? address,
  }) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _authService.updateProfile(
      uid: uid,
      displayName: displayName,
      phone: phone,
      address: address,
    );
    if (displayName != null) _profile['displayName'] = displayName;
    if (phone != null) _profile['phone'] = phone;
    if (address != null) _profile['address'] = address;
    notifyListeners();
  }
}
