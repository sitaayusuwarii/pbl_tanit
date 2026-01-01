import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import HTTP untuk call API langsung
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_card.dart';
import '../../../config/api_config.dart'; // Pastikan path ke api_config benar

class CategoryEditPage extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoryEditPage({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  bool _isDataInitialized = false;
  bool _isSaving = false; // Loading state
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  // 🔥 FUNGSI INI YANG MEMBUAT DATA MUNCUL SAAT EDIT 🔥
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isDataInitialized) {
      Map<String, dynamic>? categoryData = widget.category;

      // Cek arguments dari Navigator.pushNamed jika widget.category kosong
      if (categoryData == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          categoryData = args;
        }
      }

      if (categoryData != null) {
        _categoryId = categoryData['id'];
        
        // Prioritaskan key 'category' (karena di list page pake key itu)
        String initialName = categoryData['category'] ?? categoryData['name'] ?? '';
        _nameController.text = initialName;
      }
      
      _isDataInitialized = true;
    }
  }

  // 🔥 FUNGSI UPDATE LANGSUNG TANPA SERVICE 🔥
  Future<void> _updateCategory() async {
    if (_formKey.currentState!.validate() && _categoryId != null) {
      setState(() => _isSaving = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        // Panggil API PUT
        final url = Uri.parse('${ApiConfig.baseUrl}/categories/$_categoryId');
        
        final response = await http.put(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': _nameController.text, // Pastikan backend terima field 'name'
          }),
        );

        if (!mounted) return;

        setState(() => _isSaving = false);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil diupdate')),
          );
          // Kembali ke halaman list dengan sinyal sukses
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${response.body}')),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Edit Kategori'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Kategori',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            AdminCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama kategori tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text(
                                  'Update',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}