import 'package:flutter/material.dart';

// โชว์ระหว่างรอ AuthProvider เช็ค session ที่ Firebase จำไว้ (persistent login)
// ตอนเปิดแอปครั้งแรก ก่อนตัดสินใจว่าจะพาไปหน้าไหน (guest/ลูกค้า/ร้านค้า)
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEFDC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assests/images/logo.png',
              width: 130,
              height: 130,
              errorBuilder: (_, error, stackTrace) => const Icon(
                Icons.ramen_dining,
                size: 100,
                color: Color(0xFFE8481C),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'กินไรดี',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8481C),
              ),
            ),
            const Text(
              'Kin Rai Dee',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE8481C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'อร่อยง่าย ได้ทุกวัน',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A5A3A),
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFE8481C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
