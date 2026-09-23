import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../services/cloudinary_service.dart';

class MenuFormPage extends StatefulWidget {
  final MenuItemModel? existing;

  const MenuFormPage({super.key, this.existing});

  @override
  State<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends State<MenuFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final TextEditingController _descriptionController;
  late String _category;
  bool _saving = false;
  bool _uploadingImage = false;

  static const _categories = [
    'อาหารจานหลัก',
    'ของทานเล่น',
    'ชุดหมูกะทะ',
    'กุ้งเผา',
    'ก๋วยเตี๋ยว',
    'ของหวาน',
    'เครื่องดื่ม',
    'เครื่องดื่มแอลกอฮอล',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item == null ? '' : item.price.toStringAsFixed(0),
    );
    _imageController = TextEditingController(text: item?.imageUrl ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _category = _categories.contains(item?.category)
        ? item!.category
        : _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Row(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.chevron_left, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Text(_isEditing ? 'แก้ไขเมนู' : 'เพิ่มเมนูใหม่'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          children: [
            const _FieldLabel('รูปภาพเมนูอาหาร'),
            _ImageUploadBox(
              imageUrl: _imageController.text,
              uploading: _uploadingImage,
              onTap: _showImageOptions,
            ),
            const SizedBox(height: 20),
            const _FieldLabel('ชื่อเมนูอาหาร'),
            _InputField(
              controller: _nameController,
              hintText: 'เช่น ข้าวกะเพราเนื้อไข่ดาว',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อเมนู'
                  : null,
            ),
            const SizedBox(height: 20),
            const _FieldLabel('ราคา (บาท)'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 49,
                  width: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '฿',
                    style: TextStyle(
                      color: Color(0xFFF0321C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputField(
                    controller: _priceController,
                    hintText: 'ระบุราคาอาหาร',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      return price == null || price < 0
                          ? 'กรุณาระบุราคา'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FieldLabel('หมวดหมู่'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDecoration(),
              dropdownColor: const Color(0xFF201D1B),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 20),
            const _FieldLabel('คำอธิบายเมนูอาหาร'),
            _InputField(
              controller: _descriptionController,
              hintText: 'อธิบายรายละเอียดอาหาร รสชาติ หรือวัตถุดิบพิเศษ...',
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF0321C),
                  disabledBackgroundColor: Colors.white70,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFF8B7B76)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF0321C), width: 2),
      ),
    );
  }

  Future<void> _showImageUrlDialog() async {
    final controller = TextEditingController(text: _imageController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เพิ่มรูปภาพเมนู'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL รูปภาพ',
            hintText: 'https://...',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('ใช้รูปภาพ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      setState(() => _imageController.text = value);
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกรูปจากเครื่อง'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('ใช้ URL รูปภาพ'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showImageUrlDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await CloudinaryService.uploadImage(result.files.single);
      if (!mounted) return;
      setState(() => _imageController.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: $error')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'category': _category,
      'imageUrl': _imageController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      final service = MenuService();
      if (_isEditing) {
        await service.updateMenuItem(widget.existing!.id, data);
      } else {
        await service.addMenuItem(
          MenuItemModel(
            id: '',
            name: data['name']! as String,
            price: data['price']! as double,
            category: data['category']! as String,
            imageUrl: data['imageUrl']! as String,
            description: data['description']! as String,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกเมนูไม่สำเร็จ: $error')));
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Color(0xFF201D1B)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8B7B76)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF0321C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final String imageUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    return Material(
      color: const Color(0xFFF8F3ED),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 160,
          child: uploading
              ? const Center(child: CircularProgressIndicator())
              : hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        _uploadPrompt(),
                  ),
                )
              : _uploadPrompt(),
        ),
      ),
    );
  }

  Widget _uploadPrompt() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, color: Color(0xFFF0321C), size: 30),
        SizedBox(height: 12),
        Text(
          'อัปโหลดรูปภาพอาหาร',
          style: TextStyle(
            color: Color(0xFFF0321C),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'รองรับไฟล์ JPG, PNG (ขนาดไม่เกิน 5MB)',
          style: TextStyle(color: Color(0xFF978984), fontSize: 11),
        ),
      ],
    );
  }
}
