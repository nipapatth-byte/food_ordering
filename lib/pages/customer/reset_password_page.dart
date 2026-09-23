import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  String? _errorText;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorText = 'กรุณากรอกอีเมล';
        _isSent = false;
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _errorText = 'กรุณากรอกอีเมลให้ถูกต้อง';
        _isSent = false;
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final error = await context.read<AuthProvider>().sendPasswordResetEmail(
      email,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorText = error;
        _isSent = false;
      });
      return;
    }

    setState(() {
      _isSent = true;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(
            fontFamily: 'FCMinimal',
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'รีเซ็ตรหัสผ่าน',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'กรอกอีเมลที่ใช้สมัครสมาชิก '
                'เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้คุณ',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'อีเมล',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              if (_isSent) ...[
                const SizedBox(height: 16),
                const Text(
                  'เราได้ส่งลิงก์รีเซ็ตรหัสผ่านให้คุณแล้ว '
                  'กรุณาตรวจสอบกล่องจดหมายและโฟลเดอร์สแปม',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _sendResetEmail,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('ส่งลิงก์รีเซ็ตรหัสผ่าน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
