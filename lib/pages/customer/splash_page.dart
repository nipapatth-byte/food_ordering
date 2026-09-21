import 'package:flutter/material.dart';

// โชว์ระหว่างรอ AuthProvider เช็ค session ที่ Firebase จำไว้ (persistent login)
// ตอนเปิดแอปครั้งแรก ก่อนตัดสินใจว่าจะพาไปหน้าไหน (guest/ลูกค้า/ร้านค้า)
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assests/images/page1.png',
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => const ColoredBox(
              color: Color(0xFFFFF8E9),
              child: Icon(
                Icons.restaurant,
                size: 100,
                color: Color(0xFFE8481C),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: Column(
              children: const [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFFE6391A),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'กำลังโหลดความอร่อย...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6391A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
