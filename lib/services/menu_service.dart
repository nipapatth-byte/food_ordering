import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_item_model.dart';

class MenuService {
  final _db = FirebaseFirestore.instance;

  // ---------- ส่วนเมนูจริงของร้าน (เก็บใน Firestore) ----------

  // ฟังเมนูทั้งหมดแบบ real-time
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

  // =====================================================
  // DAILY SPECIAL
  // =====================================================

  Future<MenuItemModel?> fetchDailySpecial() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final specialRef = _db
        .collection('app_settings')
        .doc('daily_special');

    try {
      // =====================================================
      // 1. อ่าน Daily Special ปัจจุบัน
      // =====================================================

      final cached = await specialRef.get();
      Map<String, dynamic>? meal = cached.data();

      final currentDate = meal?['date']?.toString() ?? '';

      // =====================================================
      // 2. ถ้ายังไม่ใช่วันนี้ -> สุ่มจาก API
      // =====================================================

      if (currentDate != today) {
        final response = await http.get(
          Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/random.php',
          ),
        );

        if (response.statusCode != 200) {
          return null;
        }

        final data =
            jsonDecode(response.body) as Map<String, dynamic>;

        final meals = data['meals'] as List?;

        final apiMeal =
            meals != null && meals.isNotEmpty ? meals.first : null;

        if (apiMeal is! Map) {
          return null;
        }

        final newMeal = <String, dynamic>{
          'date': today,
          'mealId': apiMeal['idMeal']?.toString() ?? '',
          'name': apiMeal['strMeal']?.toString() ?? '',
          'imageUrl': apiMeal['strMealThumb']?.toString() ?? '',
          'category': apiMeal['strCategory']?.toString() ?? '',
          'description':
              apiMeal['strInstructions']?.toString() ?? '',
        };

        final newExternalId =
            newMeal['mealId']?.toString() ?? '';

        if (newExternalId.isEmpty) {
          return null;
        }

        // =====================================================
        // 3. บันทึก Daily Special
        // =====================================================

        try {
          await specialRef.set(newMeal);
          meal = newMeal;
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            // ถ้าผู้ใช้ไม่มีสิทธิ์เขียน
            // ให้ลองอ่านข้อมูลล่าสุดแทน
            final latest = await specialRef.get();
            meal = latest.data();

            if (meal?['date']?.toString() != today) {
              return null;
            }
          } else {
            rethrow;
          }
        }

        // =====================================================
        // 4. ลบ External Menu เก่าทิ้ง
        // =====================================================

        final externalId =
            meal?['mealId']?.toString() ?? '';

        if (externalId.isNotEmpty) {
          await _removePreviousExternalMenus(externalId);
        }
      }

      // =====================================================
      // 5. ตรวจข้อมูล Daily Special
      // =====================================================

      final externalId =
          meal?['mealId']?.toString() ?? '';

      if (externalId.isEmpty) {
        return null;
      }

      // =====================================================
      // 6. หาเมนู API ใน menu_items
      // =====================================================

      final existing = await _db
          .collection('menu_items')
          .where(
            'externalId',
            isEqualTo: externalId,
          )
          .limit(1)
          .get();

      // =====================================================
      // 7. ถ้ายังไม่มี -> สร้างใหม่ ราคา 0
      // =====================================================

      if (existing.docs.isEmpty) {
        final item = MenuItemModel(
          id: 'external_$externalId',
          name: meal?['name']?.toString() ?? 'เมนูพิเศษ',
          price: 0,
          category:
              meal?['category']?.toString() ?? 'อาหารจานหลัก',
          imageUrl:
              meal?['imageUrl']?.toString() ?? '',
          description:
              meal?['description']?.toString() ?? '',
          externalId: externalId,
          source: 'external',
        );

        try {
          await _db
              .collection('menu_items')
              .doc(item.id)
              .set(item.toMap());

          return item;
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            // ถ้าเขียนไม่ได้ ให้ลองอ่านใหม่
            final retry = await _db
                .collection('menu_items')
                .where(
                  'externalId',
                  isEqualTo: externalId,
                )
                .limit(1)
                .get();

            if (retry.docs.isEmpty) {
              return null;
            }

            return MenuItemModel.fromMap(
              retry.docs.first.id,
              retry.docs.first.data(),
            );
          }

          rethrow;
        }
      }

      // =====================================================
      // 8. มีเมนูอยู่แล้ว -> ใช้ของเดิม
      // =====================================================

      return MenuItemModel.fromMap(
        existing.docs.first.id,
        existing.docs.first.data(),
      );
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // ลบ External Menu เก่าของวันก่อน
  // ลูกค้าไม่มีสิทธิ์ลบ -> ไม่ให้แอปล้ม
  // =====================================================

  Future<void> _removePreviousExternalMenus(
    String currentExternalId,
  ) async {
    final snapshot = await _db
        .collection('menu_items')
        .where(
          'source',
          isEqualTo: 'external',
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      final externalId =
          doc.data()['externalId']?.toString() ?? '';

      if (externalId != currentExternalId) {
        batch.delete(doc.reference);
      }
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // ลูกค้าไม่มีสิทธิ์ลบเมนูเก่า
      // ไม่ให้ fetchDailySpecial() พัง
      if (e.code == 'permission-denied') {
        return;
      }

      rethrow;
    }
  }

  // =====================================================
  // เพิ่มเมนูใหม่ (ฝั่งร้านค้าใช้)
  // =====================================================

  Future<void> addMenuItem(MenuItemModel item) async {
    await _db
        .collection('menu_items')
        .add(item.toMap());
  }

  // =====================================================
  // แก้ไขเมนู
  // =====================================================

  Future<void> updateMenuItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('menu_items')
        .doc(id)
        .update(data);
  }

  // =====================================================
  // ลบเมนู
  // =====================================================

  Future<void> deleteMenuItem(String id) async {
    await _db
        .collection('menu_items')
        .doc(id)
        .delete();
  }

  // =====================================================
  // ส่วน TheMealDB API
  // =====================================================

  Future<Map<String, dynamic>?> fetchTodaysSpecial() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/random.php',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meal = data['meals']?[0];

        if (meal == null) {
          return null;
        }

        return {
          'name': meal['strMeal'] ?? '',
          'imageUrl': meal['strMealThumb'] ?? '',
          'category': meal['strCategory'] ?? '',
          'instructions': meal['strInstructions'] ?? '',
        };
      }

      return null;
    } catch (e) {
      // ไม่มีเน็ต หรือ API ล่ม
      return null;
    }
  }
}