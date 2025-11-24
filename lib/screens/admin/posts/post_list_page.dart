import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';
import 'post_detail_page.dart';

class PostListPage extends StatefulWidget {
  const PostListPage({Key? key}) : super(key: key);

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> posts = [
    {
      'id': 1,
      'title': 'Tips Menanam Padi di Musim Kemarau',
      'author': 'Budi Santoso',
      'category': 'Pertanian Organik',
      'likes': 45,
      'comments': 12,
      'date': '2024-11-15',
    },
    {
      'id': 2,
      'title': 'Cara Merawat Tanaman Cabai',
      'author': 'Siti Aminah',
      'category': 'Pertanian Organik',
      'likes': 38,
      'comments': 8,
      'date': '2024-11-14',
    },
    {
      'id': 3,
      'title': 'Teknologi Drone untuk Pertanian Modern',
      'author': 'Ahmad Wijaya',
      'category': 'Teknologi Pertanian',
      'likes': 52,
      'comments': 15,
      'date': '2024-11-13',
    },
  ];

  void _deletePost(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Postingan berhasil dihapus')),
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
      appBar: const AdminAppBar(title: 'Manajemen Postingan'),
      drawer: const AdminSidebar(currentRoute: '/admin/posts'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari postingan...',
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

            // List Posts
            ...posts.map((post) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(post: post),
                        ),
                      );
                    },
                    child: AdminCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon kiri
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.article,
                                color: Colors.green.shade700),
                          ),

                          const SizedBox(width: 16),

                          // Title + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Author: ${post['author']} • ${post['category']}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post['date'],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tombol aksi
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _deletePost(post['id']),
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PostDetailPage(post: post),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_ios),
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
