import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';
import '../../../services/category_service.dart'; // Import service

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService(); // Inisialisasi service
  
  List<dynamic> _categories = []; // List kosong untuk menampung data API
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Panggil data saat halaman dibuka
  }

  // Fungsi mengambil data dari API
  Future<void> _fetchCategories() async {
    try {
      final data = await _categoryService.getCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Fungsi refresh saat tarik layar (opsional tapi bagus UX-nya)
  Future<void> _handleRefresh() async {
    await _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteCategory(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu
              
              // Panggil API delete
              bool success = await _categoryService.deleteCategory(id);
              
              if (success) {
                _fetchCategories(); // Refresh list setelah hapus
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil dihapus')),
                  );
                }
              } else {
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus kategori')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Manajemen Kategori'),
      drawer: const AdminSidebar(currentRoute: '/admin/categories'),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Tunggu hasil dari halaman Add, jika true (berhasil simpan), refresh list
          final result = await Navigator.pushNamed(context, '/admin/categories/add');
          if (result == true) {
            _fetchCategories();
          }
        },
        label: const Text('Tambah Kategori'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      body: RefreshIndicator( // Bungkus dengan RefreshIndicator
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Kategori',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 24),

              // SEARCH BAR (Logika filter search belum diterapkan di backend, ini hanya UI)
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LOGIKA TAMPILAN (Loading / Kosong / Ada Data)
              if (_isLoading) 
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                 const Center(child: Text("Belum ada kategori"))
              else
                // LIST KATEGORI DARI API
                ..._categories.map((category) {
                  // Parsing tanggal (opsional, sederhana saja dulu)
                  String dateStr = category['created_at'] != null 
                      ? category['created_at'].toString().substring(0, 10) 
                      : '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: AdminCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.category, 
                                color: Colors.green.shade700),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // PERHATIKAN: Key dari Laravel adalah 'category', bukan 'name'
                                  category['category'] ?? 'Tanpa Nama',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  // Post count belum ada di tabel database, kita hardcode 0 dulu
                                  "Total Postingan: 0", 
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Dibuat: $dateStr",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Navigasi Edit (Belum diimplementasikan di jawaban ini)
                                },
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                tooltip: 'Edit',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _deleteCategory(category['id']),
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                tooltip: 'Hapus',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}