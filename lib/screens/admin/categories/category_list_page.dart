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
  // Mock data - replace with API calls
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
            onPressed: () {
              // Handle delete - call API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Kategori',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/categories/add');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kategori'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            AdminCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade50,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Nama Kategori',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Jumlah Post',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tanggal Dibuat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Aksi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: categories.map((category) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            category['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(Text(category['postCount'].toString())),
                        DataCell(Text(category['createdAt'])),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/admin/categories/edit',
                                    arguments: category,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category['id']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
