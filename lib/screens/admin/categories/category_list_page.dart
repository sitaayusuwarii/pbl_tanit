import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';
import '../../../services/category_service.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService();
  
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _categoryService.getCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error silent or snackbar
    }
  }

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
              Navigator.pop(context); 
              bool success = await _categoryService.deleteCategory(id);
              if (success) {
                _fetchCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil dihapus')),
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

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              if (_isLoading) 
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                 const Center(child: Text("Belum ada kategori"))
              else
                ..._categories.map((category) {
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
                                  category['category'] ?? 'Tanpa Nama',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                              // --- TOMBOL EDIT (SUDAH DIPERBAIKI) ---
                              IconButton(
                                onPressed: () async {
                                  // Navigasi ke Edit Page mengirimkan data kategori
                                  final result = await Navigator.pushNamed(
                                    context, 
                                    '/admin/categories/edit',
                                    arguments: category // Kirim seluruh object kategori
                                  );

                                  // Jika update berhasil (result == true), refresh list
                                  if (result == true) {
                                    _fetchCategories();
                                  }
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