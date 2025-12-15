import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _searchController = TextEditingController();

  // Mock data
  final List<Map<String, dynamic>> categories = [
    {
      'id': 1,
      'name': 'Pertanian Organik',
      'postCount': 234,
      'createdAt': '2024-01-15',
    },
    {
      'id': 2,
      'name': 'Teknologi Pertanian',
      'postCount': 189,
      'createdAt': '2024-01-20',
    },
    {
      'id': 3,
      'name': 'Peternakan',
      'postCount': 156,
      'createdAt': '2024-02-01',
    },
    {
      'id': 4,
      'name': 'Hidroponik',
      'postCount': 142,
      'createdAt': '2024-02-10',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteCategory(int id) {
    // ... (kode dialog hapus tetap sama) ...
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      
      // --- BAGIAN INI YANG BARU (TOMBOL MELAYANG DI KANAN BAWAH) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/categories/add');
        },
        label: const Text('Tambah Kategori'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      // -------------------------------------------------------------

      body: SingleChildScrollView(
        // Tambahkan padding bawah ekstra agar list paling bawah tidak tertutup tombol
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Hanya Judul (Tombol Add sudah pindah ke bawah)
            const Text(
              'Daftar Kategori',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 24),

            // SEARCH BAR
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

            // LIST KATEGORI
            ...categories.map((category) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AdminCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. ICON KIRI
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

                        // 2. TEXT TENGAH
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Total Postingan: ${category['postCount']}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Dibuat: ${category['createdAt']}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. TOMBOL AKSI
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/admin/categories/edit',
                                  arguments: category,
                                );
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
                )),
          ],
        ),
      ),
    );
  }
}