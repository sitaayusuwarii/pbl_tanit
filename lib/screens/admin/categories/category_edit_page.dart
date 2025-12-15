import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_card.dart';

class CategoryEditPage extends StatefulWidget {
  // Constructor ini sebenarnya tidak terpakai jika pakai pushNamed + arguments,
  // tapi kita biarkan saja agar kompatibel.
  final Map<String, dynamic>? category;

  const CategoryEditPage({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  // Flag untuk memastikan data hanya diambil sekali
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi awal controller (kosong dulu)
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Kita ambil arguments di sini karena context baru tersedia sepenuhnya
    if (!_isDataInitialized) {
      // 1. Coba ambil dari Constructor (jika ada)
      Map<String, dynamic>? categoryData = widget.category;

      // 2. Jika Constructor kosong, ambil dari Arguments (pushNamed)
      if (categoryData == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          categoryData = args;
        }
      }

      // 3. Isi Controller dengan data yang ditemukan
      if (categoryData != null) {
        _nameController.text = categoryData['name'] ?? '';
      }
      
      _isDataInitialized = true;
    }
  }

  void _updateCategory() {
    if (_formKey.currentState!.validate()) {
      // Handle update - call API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil diupdate')),
      );
      Navigator.pop(context);
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
                      controller: _nameController, // Controller sudah terisi otomatis
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
                            onPressed: _updateCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
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