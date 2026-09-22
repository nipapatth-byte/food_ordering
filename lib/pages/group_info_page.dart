import 'package:flutter/material.dart';

class GroupInfoAction extends StatelessWidget {
  const GroupInfoAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'ข้อมูลสมาชิกกลุ่ม',
      icon: const Icon(Icons.groups_outlined),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupInfoPage()),
      ),
    );
  }
}

class GroupInfoPage extends StatelessWidget {
  const GroupInfoPage({super.key});

  static const members = [
    (
      'นางสาวนิภาภัทร์ ธรรมสิริ',
      'รหัสนิสิต: 6721602474',
      'lib/assests/images/profile.jpeg',
    ),
    (
      'นายรภีพัส เพชรทอง',
      'รหัสนิสิต: 6721602571',
      'lib/assests/images/profile1.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            Row(
              children: [
                _BackButton(onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 14),
                const Text(
                  'เกี่ยวกับแอป',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ClipOval(
                child: Image.asset(
                  'lib/assests/images/kinraidee.png',
                  width: 186,
                  height: 186,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'กินไรดี (Kin Rai Dee)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'แอปจัดการร้านอาหาร',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'สมาชิก',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberCard(member: member),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.chevron_left, color: Colors.black, size: 25),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final (String, String, String) member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 23, backgroundImage: AssetImage(member.$3)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF241B18),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  member.$2,
                  style: const TextStyle(
                    color: Color(0xFF8C7D77),
                    fontSize: 12,
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

class _TechnologyChip extends StatelessWidget {
  final String label;

  const _TechnologyChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF302723),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
