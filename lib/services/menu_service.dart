import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_item_model.dart';

class MenuService {
  final _db = FirebaseFirestore.instance;

  // ---------- ส่วนเมนูจริงของร้าน (เก็บใน Firestore) ----------

  // ฟังเมนูทั้งหมดแบบ real-time (ถ้าร้านแก้ไข/เพิ่มเมนู ทุกเครื่องที่เปิดอยู่จะเห็นทันที)
  Stream<List<MenuItemModel>> streamAllMenu() {
    return _db
        .collection('menu_items')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MenuItemModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ฟังเมนูเฉพาะหมวดหมู่
  Stream<List<MenuItemModel>> streamMenuByCategory(String category) {
    return _db
        .collection('menu_items')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MenuItemModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<MenuItemModel?> fetchDailySpecial() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final specialRef = _db.collection('app_settings').doc('daily_special');
    final cached = await specialRef.get();
    Map<String, dynamic>? meal = cached.data();
    var dateChanged = meal?['date'] != today;

    if (dateChanged) {
      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final meals = data['meals'] as List?;
      final apiMeal = meals != null && meals.isNotEmpty ? meals.first : null;
      if (apiMeal is! Map) return null;
      meal = {
        'date': today,
        'mealId': apiMeal['idMeal']?.toString() ?? '',
        'name': apiMeal['strMeal']?.toString() ?? '',
        'imageUrl': apiMeal['strMealThumb']?.toString() ?? '',
        'category': apiMeal['strCategory']?.toString() ?? '',
        'description': apiMeal['strInstructions']?.toString() ?? '',
      };
      await specialRef.set(meal);
    }

    final externalId = meal?['mealId']?.toString() ?? '';
    if (externalId.isEmpty) return null;

    if (dateChanged) {
      await _removePreviousExternalMenus(externalId);
    }

    final existing = await _db
        .collection('menu_items')
        .where('externalId', isEqualTo: externalId)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      final item = MenuItemModel(
        id: 'external_$externalId',
        name: meal?['name']?.toString() ?? 'เมนูพิเศษ',
        price: 0,
        category: meal?['category']?.toString() ?? 'อาหารจานหลัก',
        imageUrl: meal?['imageUrl']?.toString() ?? '',
        description: meal?['description']?.toString() ?? '',
        externalId: externalId,
        source: 'external',
      );
      await _db.collection('menu_items').doc(item.id).set(item.toMap());
      return item;
    }
    return MenuItemModel.fromMap(
      existing.docs.first.id,
      existing.docs.first.data(),
    );
  }

  Future<void> _removePreviousExternalMenus(String currentExternalId) async {
    final snapshot = await _db
        .collection('menu_items')
        .where('source', isEqualTo: 'external')
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final externalId = doc.data()['externalId']?.toString() ?? '';
      if (externalId != currentExternalId) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  // เพิ่มเมนูใหม่ (ฝั่งร้านค้าใช้)
  Future<void> addMenuItem(MenuItemModel item) async {
    await _db.collection('menu_items').add(item.toMap());
  }

  // แก้ไขเมนู
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await _db.collection('menu_items').doc(id).update(data);
  }

  // ลบเมนู
  Future<void> deleteMenuItem(String id) async {
    await _db.collection('menu_items').doc(id).delete();
  }

  // ---------- ส่วน TheMealDB API (สุ่มเมนูแนะนำ "Today's Special") ----------
  // หมายเหตุ: อันนี้แค่ดึงมาโชว์เป็นแรงบันดาลใจ/รูปประกอบ ไม่เกี่ยวกับเมนูจริงของร้านใน Firestore

  Future<Map<String, dynamic>?> fetchTodaysSpecial() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meal = data['meals']?[0];
        if (meal == null) return null;
        return {
          'name': meal['strMeal'] ?? '',
          'imageUrl': meal['strMealThumb'] ?? '',
          'category': meal['strCategory'] ?? '',
          'instructions': meal['strInstructions'] ?? '',
        };
      }
      return null;
    } catch (e) {
      // ไม่มีเน็ต หรือ API ล่ม -> คืน null ให้ UI แสดง fallback เอง
      return null;
    }
  }
}
