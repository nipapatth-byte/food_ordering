import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/menu_item_model.dart';

class MenuService {
  final _db = FirebaseFirestore.instance;

  // ลำดับหมวดที่ต้องการ (แก้ลำดับตรงนี้ได้เลย)
  static const List<String> categoryOrder = [
    'อาหารจานหลัก',
    'ก๋วยเตี๋ยว',
    'กุ้งเผา',
    'ชุดหมูกะทะ',
    'ของทานเล่น',
    'ของหวาน',
    'เครื่องดื่ม',
    'เครื่องดื่มแอลกอฮอล',
  ];

  static List<MenuItemModel> _sortMenu(List<MenuItemModel> items) {
    int rank(String c) {
      final i = categoryOrder.indexOf(c);
      return i == -1 ? categoryOrder.length : i; // หมวดที่ไม่รู้จักไปท้ายสุด
    }

    items.sort((a, b) {
      final c = rank(a.category).compareTo(rank(b.category));
      if (c != 0) return c;
      return a.name.compareTo(b.name); // ในหมวดเดียวกันเรียงตามชื่อ
    });
    return items;
  }

  Stream<List<MenuItemModel>> streamAllMenu() {
    return _db
        .collection('menu_items')
        .snapshots()
        .map(
          (snap) => _sortMenu(
            snap.docs
                .map((doc) => MenuItemModel.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  // =====================================================
  // DAILY SPECIAL
  // =====================================================

  Future<MenuItemModel?> fetchDailySpecial() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final specialRef = _db.collection('app_settings').doc('daily_special');

    try {
      // =====================================================
      // 1. อ่าน Daily Special ปัจจุบัน
      // =====================================================

      final cached = await specialRef.get();
      Map<String, dynamic>? meal = cached.data();
      final currentDate = meal?['date']?.toString() ?? '';

      // ถ้าวันนี้มีเมนูอยู่แล้ว ไม่ต้องเรียก API ซ้ำ
      if (currentDate == today) {
        return await _ensureDailyMenuItem(meal!);
      }

      // Guest อ่านเมนูได้ แต่ไม่มีสิทธิ์สร้างเมนูประจำวัน
      // ให้ลูกค้าที่ login แล้วเป็นคนแรกที่เปิด Home เพื่อเริ่มวันใหม่
      if (FirebaseAuth.instance.currentUser == null) {
        return null;
      }

      // =====================================================
      // 2. วันใหม่ -> เรียก TheMealDB API
      // =====================================================
      //
      // หมายเหตุ:
      // ถ้ามีหลายคนเปิดพร้อมกัน อาจมีการเรียก API มากกว่า 1 ครั้ง
      // แต่ Firestore Transaction ด้านล่างจะเลือก Daily Special
      // ที่ถูกบันทึกจริงเพียง 1 เมนูต่อวัน
      // =====================================================

      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final meals = data['meals'] as List?;
      final apiMeal = meals != null && meals.isNotEmpty ? meals.first : null;

      if (apiMeal is! Map) {
        return null;
      }

      final newMeal = <String, dynamic>{
        'date': today,
        'mealId': apiMeal['idMeal']?.toString() ?? '',
        'name': apiMeal['strMeal']?.toString() ?? '',
        'imageUrl': apiMeal['strMealThumb']?.toString() ?? '',
        'category': apiMeal['strCategory']?.toString() ?? '',
        'description': apiMeal['strInstructions']?.toString() ?? '',
      };

      if ((newMeal['mealId']?.toString() ?? '').isEmpty) {
        return null;
      }

      // =====================================================
      // 3. Transaction: ให้ Daily Special ของวันนี้มีได้ 1 ตัว
      // =====================================================
      //
      // คนที่มาถึงก่อนจะเป็นคนบันทึกเมนูของวันนี้
      // คนอื่นที่กำลังทำงานพร้อมกันจะอ่านค่าที่คนแรกบันทึกไว้
      // =====================================================

      meal = await _db.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        final latestSnapshot = await transaction.get(specialRef);
        final latest = latestSnapshot.data();
        final latestDate = latest?['date']?.toString() ?? '';

        if (latest != null && latestDate == today) {
          return Map<String, dynamic>.from(latest);
        }

        transaction.set(specialRef, newMeal);
        return newMeal;
      });

      // =====================================================
      // 4. ลบ External Menu เก่าของวันก่อน
      // =====================================================

      final externalId = meal['mealId']?.toString() ?? '';
      if (externalId.isEmpty) {
        return null;
      }

      await _removePreviousExternalMenus();

      // =====================================================
      // 5. สร้าง/อ่านเมนู API ของวันนี้
      // =====================================================

      return await _ensureDailyMenuItem(meal);
    } catch (_) {
      // ไม่มีเน็ต / Firebase error / API error
      // ไม่ให้หน้า Home พัง
      return null;
    }
  }

  // =====================================================
  // สร้างเมนู API ใน menu_items ถ้ายังไม่มี
  // ราคาเริ่มต้น = 0
  // =====================================================

  Future<MenuItemModel?> _ensureDailyMenuItem(Map<String, dynamic> meal) async {
    final externalId = meal['mealId']?.toString() ?? '';
    final dailyDate = meal['date']?.toString() ?? '';

    if (externalId.isEmpty || dailyDate.isEmpty) {
      return null;
    }

    final docRef = _db.collection('menu_items').doc('external_$externalId');
    final existing = await docRef.get();

    if (existing.exists) {
      return MenuItemModel.fromMap(existing.id, existing.data()!);
    }

    final item = MenuItemModel(
      id: 'external_$externalId',
      name: meal['name']?.toString() ?? 'เมนูพิเศษ',
      price: 0,
      category: meal['category']?.toString() ?? 'อาหารจานหลัก',
      imageUrl: meal['imageUrl']?.toString() ?? '',
      description: meal['description']?.toString() ?? '',
      externalId: externalId,
      source: 'external',
      dailyDate: dailyDate,
    );

    try {
      // ใช้ ID เดิมจาก externalId เพื่อให้หลายคนที่เปิดพร้อมกัน
      // เขียนลง document เดียวกัน ไม่สร้างหลาย document
      await docRef.set(item.toMap());

      return item;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        final retry = await docRef.get();
        if (!retry.exists) {
          return null;
        }

        return MenuItemModel.fromMap(retry.id, retry.data()!);
      }

      rethrow;
    }
  }

  // =====================================================
  // ลบ External Menu เก่าของวันก่อน
  // ไม่มีปุ่มให้ลูกค้ากด
  // ระบบเรียกใช้เบื้องหลังตอนขึ้นวันใหม่
  // =====================================================

  Future<void> _removePreviousExternalMenus() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final snapshot = await _db
        .collection('menu_items')
        .where('source', isEqualTo: 'external')
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final oldDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final dailyDate = data['dailyDate']?.toString() ?? '';

      // dailyDate ว่าง = เมนูเก่าจากระบบเวอร์ชันก่อนหน้า
      return dailyDate != today;
    }).toList();

    if (oldDocs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in oldDocs) {
      batch.delete(doc.reference);
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // ถ้าผู้ใช้ไม่มีสิทธิ์ลบ หรือเกิดปัญหาในการลบ
      // ไม่ให้การสร้างเมนูประจำวันพัง
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
    await _db.collection('menu_items').add(item.toMap());
  }

  // =====================================================
  // แก้ไขเมนู
  // =====================================================

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await _db.collection('menu_items').doc(id).update(data);
  }

  // =====================================================
  // ลบเมนู
  // =====================================================

  Future<void> deleteMenuItem(String id) async {
    await _db.collection('menu_items').doc(id).delete();
  }

  // =====================================================
  // ส่วน TheMealDB API แบบเดิม
  // เก็บไว้เพื่อไม่ให้ส่วนอื่นของแอปที่เรียกใช้พัง
  // =====================================================

  Future<Map<String, dynamic>?> fetchTodaysSpecial() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'),
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
    } catch (_) {
      // ไม่มีเน็ต หรือ API ล่ม
      return null;
    }
  }
}
