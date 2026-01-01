import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart'; // Pastikan path ini sesuai dengan struktur foldermu

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk Input Text
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // Atau Email, sesuaikan backend kamu
  final _passCtrl = TextEditingController();
  
  // Default Role yang dipilih
  String _selectedRole = 'admin'; 
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // --- FUNGSI KIRIM DATA KE API ---
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Panggil Endpoint Laravel
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/create-user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(), // Pastikan backend terima 'phone' (atau ubah jadi 'email')
          'password': _passCtrl.text.trim(),
          'role': _selectedRole, // 'admin' atau 'petani'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
          // Kembali ke halaman list user setelah berhasil
          Navigator.pop(context); 
        }
      } else {
        // Handle Error Validasi dari Laravel
        final body = jsonDecode(response.body);
        String errorMessage = body['message'] ?? 'Gagal membuat user';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Akun Baru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Password default disarankan: 123456. User dapat menggantinya nanti.",
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. INPUT NAMA
              _buildLabel("Nama Lengkap"),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration("Contoh: Admin Staff 2"),
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // 2. INPUT NOMOR HP / EMAIL
              // Sesuaikan label ini dengan database kamu (Phone atau Email)
              _buildLabel("Nomor HP / Username"), 
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Contoh: 08123456789"),
                validator: (v) => v!.isEmpty ? 'Nomor HP wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // 3. INPUT PASSWORD
              _buildLabel("Password"),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: _inputDecoration("Minimal 6 karakter").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 20),

              // 4. PILIH ROLE (DROPDOWN)
              _buildLabel("Role User"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.orange),
                            SizedBox(width: 10),
                            Text('Admin Staff'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'petani',
                        child: Row(
                          children: [
                            Icon(Icons.agriculture, color: Colors.green),
                            SizedBox(width: 10),
                            Text('Petani'),
                          ],
                        ),
                      ),
                      // Opsional: Jika Super Admin mau bikin Super Admin lain
                      // DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _createUser,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Buat User Baru",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  // Helper Widget untuk Style Input
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }
}