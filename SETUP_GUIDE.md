# คู่มือ Setup โปรเจกต์ Restaurant App ตั้งแต่เริ่มต้น

ทำตามลำดับนี้ทีละขั้น อย่าข้าม เพราะแต่ละขั้นเป็นฐานของขั้นถัดไป

---

## ขั้นที่ 1: สร้างโปรเจกต์ Flutter ใหม่

เปิด Terminal (VS Code หรือเครื่อง) แล้วรัน:

```bash
flutter create restaurant_app
cd restaurant_app
```

จะได้โปรเจกต์เปล่าที่มีโครง `lib/main.dart` เริ่มต้นมาให้ (ไฟล์ default ที่มันสร้างให้ ลบทิ้งเนื้อหาข้างในได้เลย เดี๋ยวจะแทนที่ด้วยไฟล์ใน zip ที่แนบมา)

---

## ขั้นที่ 2: สร้าง Firebase Project ใหม่ (ไม่ใช้ project เดิมจาก lab)

1. ไปที่ [console.firebase.google.com](https://console.firebase.google.com)
2. กด **Add project** → ตั้งชื่อ เช่น `restaurant-app-yourname`
3. ปิด Google Analytics ได้ (ไม่จำเป็นสำหรับโปรเจกต์นี้) → กด Create project
4. รอจน project สร้างเสร็จ

### เปิดใช้งาน Authentication
1. เมนูซ้าย → **Build** → **Authentication** → กด **Get started**
2. แท็บ **Sign-in method** → เลือก **Email/Password** → กด **Enable** → **Save**

### เปิดใช้งาน Firestore Database
1. เมนูซ้าย → **Build** → **Firestore Database** → กด **Create database**
2. เลือก **Start in test mode** (สำหรับพัฒนา จะได้ไม่ต้องตั้ง security rules ตอนนี้)
3. เลือก location (เช่น `asia-southeast1` ใกล้ไทยสุด) → Enable

---

## ขั้นที่ 3: ผูก Flutter Project เข้ากับ Firebase

ใน Terminal ที่โฟลเดอร์โปรเจกต์:

```bash
# ติดตั้ง Firebase CLI (ถ้ายังไม่มี)
npm install -g firebase-tools

# login เข้า Firebase ด้วย Google account
firebase login

# ติดตั้ง FlutterFire CLI (ถ้ายังไม่มี)
dart pub global activate flutterfire_cli

# ผูกโปรเจกต์ — จะมี list ให้เลือก Firebase project ที่สร้างในขั้นที่ 2
flutterfire configure
```

ตอนรัน `flutterfire configure`:
- เลือก Firebase project ที่สร้างไว้ (`restaurant-app-yourname`)
- เลือก platform: `android`, `ios` (ถ้าจะรันทั้งสอง เลือกทั้งคู่ด้วย spacebar แล้ว enter)

คำสั่งนี้จะสร้างไฟล์ `lib/firebase_options.dart` ให้อัตโนมัติ **ห้ามลบไฟล์นี้**

---

## ขั้นที่ 4: เพิ่ม Dependencies ใน pubspec.yaml

เปิดไฟล์ `pubspec.yaml` เพิ่มใต้ `dependencies:`

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  provider: ^6.1.2
  http: ^1.2.2
  cupertino_icons: ^1.0.8
```

จากนั้นรัน:
```bash
flutter pub get
```

---

## ขั้นที่ 5: วางไฟล์โค้ดทั้งหมด

แตกไฟล์ zip ที่ได้รับ แล้ว **คัดลอกทุกอย่างในโฟลเดอร์ `lib/` ทับ** ลงในโฟลเดอร์ `lib/` ของโปรเจกต์ (ยกเว้น `firebase_options.dart` ที่ได้จากขั้นที่ 3 ห้ามทับ ให้เก็บของจริงที่ `flutterfire configure` สร้างให้ไว้)

โครงสร้างที่ควรได้หลังวางไฟล์:
```
lib/
├── main.dart
├── firebase_options.dart   ← อันนี้ต้องเป็นไฟล์จริงจาก flutterfire configure
├── models/
├── services/
├── providers/
├── pages/
└── widgets/
```

---

## ขั้นที่ 6: แก้ Android build config (จำเป็นสำหรับ Firebase Auth)

เปิด `android/app/build.gradle.kts` เช็คว่ามีบรรทัดนี้อยู่ในส่วน `android { }`:

```kotlin
android {
    defaultConfig {
        minSdk = 23   // Firebase Auth ต้องการอย่างน้อย 23
    }
}
```

ถ้า `minSdk` ต่ำกว่า 23 ให้แก้เป็น 23

---

## ขั้นที่ 7: สร้างข้อมูลเริ่มต้นใน Firestore (ทำมือผ่าน Console)

เข้า Firestore Database ใน Firebase Console → กด **Start collection**

### สร้าง collection `menu_items` ใส่ตัวอย่าง 2-3 เมนู เช่น
```
Document ID: (auto-generate)
  name: "ผัดไทยกุ้งสด"
  price: 60
  category: "จานเดียว"
  imageUrl: "https://..."
  description: "ผัดไทยรสชาติต้นตำรับ"
```

### สร้าง collection `tables` ใส่โต๊ะตัวอย่าง เช่น
```
Document ID: (auto-generate)
  tableNumber: 1
  seatCount: 4
  status: "available"
```
ทำซ้ำสัก 6-8 โต๊ะ

---

## ขั้นที่ 8: รันแอปทดสอบ

```bash
flutter run
```

เลือกเครื่อง (emulator หรือมือถือจริงที่ต่อ USB) ที่ต้องการรัน

**ทดสอบว่า Firebase เชื่อมสำเร็จ:** ถ้าเปิดแอปแล้วไม่ error แดงเรื่อง Firebase ตอน initialize แสดงว่าเชื่อมสำเร็จแล้ว ลองกด tab โปรไฟล์ → สมัครสมาชิกทดสอบ 1 บัญชี → เช็คใน Firebase Console → Authentication → Users ว่ามีบัญชีขึ้นมาจริง

---

## ขั้นที่ 9 (ทำท้ายสุด ก่อนส่งงาน): ตั้ง Firestore Security Rules

ตอนพัฒนาใช้ test mode ได้ แต่ก่อนส่งงานควรเปลี่ยนเป็นแบบนี้อย่างน้อย (Firestore → Rules):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

กฎนี้อนุญาตให้ทุกคนอ่านได้ (ดูเมนู/โต๊ะ) แต่เขียนได้เฉพาะคนที่ login แล้วเท่านั้น

---

## สรุปลำดับที่ต้องทำ

1. `flutter create restaurant_app`
2. สร้าง Firebase project ใหม่ + เปิด Auth + เปิด Firestore
3. `flutterfire configure`
4. เพิ่ม dependencies ใน pubspec.yaml + `flutter pub get`
5. วางไฟล์โค้ดจาก zip ทับใน `lib/`
6. เช็ค `minSdk = 23` ใน Android
7. เพิ่มข้อมูลตัวอย่างใน Firestore Console (menu_items, tables)
8. `flutter run`
9. ตั้ง security rules ก่อนส่งงานจริง
