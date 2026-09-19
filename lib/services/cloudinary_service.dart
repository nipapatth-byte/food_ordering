import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dlk4gmnl';
  static const String _uploadPreset = 'flutter_food_app';

  static Future<String> uploadImage(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('ไม่สามารถอ่านไฟล์รูปภาพได้');
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('ไฟล์รูปภาพต้องมีขนาดไม่เกิน 5 MB');
    }

    final response = await http.post(
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      body: {
        'upload_preset': _uploadPreset,
        'file':
            'data:${file.extension == 'png' ? 'image/png' : 'image/jpeg'};base64,'
            '${base64Encode(bytes)}',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary อัปโหลดไม่สำเร็จ (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary ไม่ส่ง URL รูปภาพกลับมา');
    }
    return secureUrl;
  }
}
