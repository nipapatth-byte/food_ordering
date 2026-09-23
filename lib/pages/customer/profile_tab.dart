import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../group_info_page.dart';
import 'reset_password_page.dart';

// หน้านี้ทำหน้าที่ 2 อย่าง:
// - ยังไม่ login -> โชว์ฟอร์ม login/register (เลือก role ตอน register)
// - login แล้ว -> โชว์ข้อมูลผู้ใช้ + ปุ่ม logout
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();
  final String _selectedRole = 'customer';
  bool _isRegisterMode = false;
  String? _errorText;
  String _profileName = '';
  String _profilePhone = '';
  String _profileAddress = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: auth.isLoggedIn ? null : null,
      body: auth.isLoggedIn ? _buildLoggedInView(auth) : _buildAuthForm(auth),
    );
  }

  Widget _buildLoggedInView(AuthProvider auth) {
    return auth.role == 'seller'
        ? _buildSellerProfile(auth)
        : _buildCustomerProfile(auth);
  }

  Widget _buildCustomerProfile(AuthProvider auth) {
    final email = auth.user?.email ?? 'somchai@email.com';
    final profileName = auth.profile['displayName']?.toString().trim() ?? '';
    final profilePhone = auth.profile['phone']?.toString().trim() ?? '';
    final profileAddress = auth.profile['address']?.toString().trim() ?? '';
    if (_profileName != profileName ||
        _profilePhone != profilePhone ||
        _profileAddress != profileAddress) {
      _profileName = profileName;
      _profilePhone = profilePhone;
      _profileAddress = profileAddress;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        const _ProfileBrand(),
        const SizedBox(height: 30),
        const Center(
          child: _ProfileAvatar(
            image: 'lib/assests/images/peple.jpg',
            size: 102,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            _profileName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text(email)),
        const SizedBox(height: 24),
        const Text(
          'ข้อมูลส่วนตัว 📝',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _ProfileCard(
          label: 'ชื่อ-นามสกุล',
          value: _profileName,
          onEdit: () => _editValue('ชื่อ-นามสกุล', _profileName, (value) {
            setState(() => _profileName = value);
            context.read<AuthProvider>().updateProfile(displayName: value);
          }),
        ),
        _ProfileCard(label: 'อีเมล', value: email, onEdit: null),
        _ProfileCard(
          label: 'เบอร์โทร',
          value: _profilePhone,
          onEdit: () => _editValue('เบอร์โทร', _profilePhone, (value) {
            setState(() => _profilePhone = value);
            context.read<AuthProvider>().updateProfile(phone: value);
          }),
        ),
        _ProfileCard(
          label: 'ที่อยู่จัดส่ง',
          value: _profileAddress,
          onEdit: () => _editValue('ที่อยู่จัดส่ง', _profileAddress, (value) {
            setState(() => _profileAddress = value);
            context.read<AuthProvider>().updateProfile(address: value);
          }),
        ),
        const SizedBox(height: 4),
        _LogoutButton(onPressed: auth.logout),
      ],
    );
  }

  Widget _buildSellerProfile(AuthProvider auth) {
    final email = auth.user?.email?.trim().toLowerCase() ?? '';
    final isCompanyAdmin = email == 'admin@kinraidee.com';
    final name = isCompanyAdmin ? 'ประธานบริษัท' : 'แอดมิน กินไรดี';
    final image = isCompanyAdmin
        ? 'lib/assests/images/kinraidee.png'
        : 'lib/assests/images/chef.jpg';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        const Center(
          child: Text(
            'โปรไฟล์แอดมิน',
            style: TextStyle(
              fontFamily: 'FCMinimal',
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 36),
        Center(child: _ProfileAvatar(image: image, size: 90)),
        const SizedBox(height: 14),
        Center(
          child: Text(
            name,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            auth.user?.email ?? 'admin1@kinraidee.com',
            style: const TextStyle(color: Color(0xFFFF4D26)),
          ),
        ),
        const SizedBox(height: 28),
        _AdminInfoRow(label: 'ชื่อ-นามสกุล', value: name),
        _AdminInfoRow(
          label: 'อีเมล',
          value: auth.user?.email ?? 'admin1@kinraidee.com',
        ),
        const SizedBox(height: 40),
        _LogoutButton(onPressed: auth.logout),
      ],
    );
  }

  Future<void> _editValue(
    String label,
    String currentValue,
    ValueChanged<String> onSaved,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('แก้ไข$label'),
        content: TextField(
          controller: controller,
          maxLines: label == 'ที่อยู่จัดส่ง' ? 4 : 1,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) onSaved(value);
  }

  Widget _buildAuthForm(AuthProvider auth) {
    return SafeArea(
      child: Column(
        children: [
          if (_isRegisterMode)
            _AuthHeader(
              title: 'สมัครสมาชิก',
              onBack: () => setState(() {
                _isRegisterMode = false;
                _errorText = null;
              }),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _isRegisterMode ? 250 : 385,
                    width: double.infinity,
                    child: Image.asset(
                      'lib/assests/images/login.png',
                      fit: BoxFit.cover,
                      alignment: _isRegisterMode
                          ? Alignment.topCenter
                          : Alignment.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: _isRegisterMode
                        ? _buildRegisterFields(auth)
                        : _buildLoginFields(auth),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFields(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เข้าสู่ระบบ',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text('เพื่อสั่งอาหาร จองโต๊ะ และจัดการออเดอร์ของคุณ'),
        const SizedBox(height: 18),
        _AuthField(
          controller: _emailCtrl,
          hint: 'อีเมล',
          icon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _passCtrl,
          hint: 'รหัสผ่าน',
          icon: Icons.lock,
          obscureText: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
              );
            },
            child: const Text(
              'ลืมรหัสผ่าน?',
              style: TextStyle(
                color: Color(0xFFFF4D26),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _AuthButton(
          label: 'เข้าสู่ระบบ',
          loading: auth.isLoading,
          onPressed: () => _submit(auth),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isRegisterMode = true;
              _errorText = null;
            }),
            child: const Text(
              'ยังไม่มีบัญชี? สมัครสมาชิก',
              style: TextStyle(
                color: Color(0xFFF0321C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (_errorText != null) _ErrorText(_errorText!),
      ],
    );
  }

  Widget _buildRegisterFields(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _nameCtrl,
          hint: 'ชื่อ-สกุล',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _phoneCtrl,
          hint: 'เบอร์โทรศัพท์',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _emailCtrl,
          hint: 'อีเมล',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _passCtrl,
          hint: 'รหัสผ่าน',
          icon: Icons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 18),
        const Text(
          'ที่อยู่ในการจัดส่ง',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _AuthField(controller: _addressCtrl, hint: 'ที่อยู่', icon: Icons.home),
        const SizedBox(height: 12),
        _AuthField(
          controller: _addressDetailCtrl,
          hint: 'รายละเอียดเพิ่มเติม (ถ้ามี)',
          icon: Icons.info,
        ),
        const SizedBox(height: 24),
        _AuthButton(
          label: 'สมัครสมาชิก',
          loading: auth.isLoading,
          onPressed: () => _submit(auth),
        ),
        if (_errorText != null) _ErrorText(_errorText!),
      ],
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }
    final error = _isRegisterMode
        ? await auth.register(
            email,
            pass,
            _selectedRole,
            displayName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: [
              _addressCtrl.text.trim(),
              _addressDetailCtrl.text.trim(),
            ].where((value) => value.isNotEmpty).join(' '),
          )
        : await auth.login(email, pass);
    if (mounted) setState(() => _errorText = error);
  }

  /*void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }*/
}

class _ProfileBrand extends StatelessWidget {
  const _ProfileBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset('lib/assests/images/chef.jpg', width: 34, height: 34),
            const SizedBox(width: 10),
            const Text(
              'โปรไฟล์',
              style: TextStyle(
                color: Color(0xFFFF4D26),
                fontFamily: 'FCMinimal',
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.person_outline),
          tooltip: 'เกี่ยวกับเรา',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupInfoPage()),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String image;
  final double size;

  const _ProfileAvatar({required this.image, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFF4D26), width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Colors.white,
            child: Icon(Icons.person, color: Color(0xFFFF4D26), size: 42),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _ProfileCard({required this.label, required this.value, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0321C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (onEdit != null) _EditCircle(onPressed: onEdit!),
        ],
      ),
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AdminInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B7B76))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF201D1B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCircle extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditCircle({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.edit_outlined, color: Color(0xFFF0321C), size: 19),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF0321C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'ออกจากระบบ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _AuthHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 24),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.chevron_left, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF201D1B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8B7B76)),
        prefixIcon: Icon(icon, color: const Color(0xFF8B7B76)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF0321C), width: 2),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D26),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message, style: const TextStyle(color: Color(0xFFFF6B5C))),
    );
  }
}
