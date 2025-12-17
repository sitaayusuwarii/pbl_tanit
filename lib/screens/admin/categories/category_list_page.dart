import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';
import 'category_add_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

 Future<void> _fetchCategories() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse("http://192.168.1.6:8000/api/categories"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("RAW RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        categories = json['data'];   // FIX DI SINI
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  } catch (e) {
    print("ERROR FETCH CATEGORIES: $e");
    setState(() => loading = false);
  }
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

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? '';

              final response = await http.delete(
                Uri.parse("http://192.168.1.6:8000/api/categories/$id"),
                headers: {"Authorization": "Bearer $token"},
              );

              if (response.statusCode == 200) {
                _fetchCategories(); // refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil dihapus')),
                );
              }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryAddPage()),
                ).then((_) => _fetchCategories());
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            loading
                ? const Center(child: CircularProgressIndicator())
                : AdminCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.grey.shade50),
                        columns: const [
                          DataColumn(label: Text('Nama Kategori')),
                          DataColumn(label: Text('Jumlah Post')),
                          DataColumn(label: Text('Tanggal Dibuat')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: categories.map((category) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                category['category'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              )),
                              DataCell(Text((category['posts_count'] ?? 0).toString())),
                              DataCell(Text(category['created_at'] ?? '-')),
                              DataCell(
                                Row(
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
                                      onPressed: () =>
                                          _deleteCategory(category['id']),
                                    ),
                                  ],
                                ),
                              )
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
