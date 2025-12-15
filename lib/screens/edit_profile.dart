import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _currentAvatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameCtrl.text = widget.userData!['name'] ?? '';
      _bioCtrl.text = widget.userData!['bio'] ?? '';
      _locationCtrl.text = widget.userData!['location'] ?? '';
      _phoneCtrl.text = widget.userData!['phone'] ?? '';
      _currentAvatarUrl = widget.userData!['avatar_url'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/user/update'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = _nameCtrl.text.trim();
      request.fields['bio'] = _bioCtrl.text.trim();
      request.fields['location'] = _locationCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();

      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            _imageBytes!,
            filename: 'avatar.jpg',
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile berhasil diperbarui'),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true); // Return true untuk refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui: $responseBody'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'PublicSans',
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : _currentAvatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                    _currentAvatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF2E7D32),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Ketuk untuk ganti foto',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Nama Lengkap
            _buildLabel('Nama Lengkap'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 15,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Masukkan nama lengkap',
                icon: Icons.person_outline,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            
            // Bio
            _buildLabel('Bio'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 15,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Ceritakan tentang diri Anda...',
                icon: Icons.info_outline,
              ),
            ),
            const SizedBox(height: 20),

            // Lokasi
            _buildLabel('Lokasi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 15,
              ),
              decoration: _buildInputDecoration(
                hintText: 'Kota, Provinsi',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 20),

            // Nomor Telepon
            _buildLabel('Nomor Telepon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 15,
              ),
              decoration: _buildInputDecoration(
                hintText: '08123456789',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'PublicSans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'PublicSans',
        color: Colors.grey[400],
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2E7D32),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}
