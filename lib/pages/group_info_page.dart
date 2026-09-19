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
    ('สมาชิกกลุ่ม 1', 'ผู้ดูแลระบบ', 'lib/assests/images/meaw.jpg'),
    ('สมาชิกกลุ่ม 2', 'นักพัฒนาแอป', 'lib/assests/images/meaw1.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลผู้พัฒนา')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final member = members[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(member.$3),
              ),
              title: Text(
                member.$1,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.$2),
            ),
          );
        },
      ),
    );
  }
}
