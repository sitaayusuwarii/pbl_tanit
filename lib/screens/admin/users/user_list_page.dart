import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _searchController = TextEditingController();

  // Mock data
  final List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'name': 'Budi Santoso',
      'email': 'budi@email.com',
      'posts': 23,
      'joined': '2024-01-10',
      'status': 'active',
    },
    {
      'id': 2,
      'name': 'Siti Aminah',
      'email': 'siti@email.com',
      'posts': 18,
      'joined': '2024-02-15',
      'status': 'active',
    },
    {
      'id': 3,
      'name': 'Ahmad Wijaya',
      'email': 'ahmad@email.com',
      'posts': 31,
      'joined': '2024-03-20',
      'status': 'active',
    },
    {
      'id': 4,
      'name': 'Dewi Lestari',
      'email': 'dewi@email.com',
      'posts': 15,
      'joined': '2024-04-05',
      'status': 'active',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteUser(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus user ini? Semua postingan user juga akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User berhasil dihapus')),
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
      appBar: const AdminAppBar(title: 'Manajemen User'),
      drawer: const AdminSidebar(currentRoute: '/admin/users'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Judul & Search Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar User',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Search Bar (Full Width)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari user...',
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

            // LIST USER (Style Card seperti Postingan)
            ...users.map((user) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      // Tetap menggunakan Route Lama (Detail)
                      Navigator.pushNamed(
                        context,
                        '/admin/users/detail',
                        arguments: user,
                      );
                    },
                    child: AdminCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. AVATAR KIRI
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.green.shade600,
                            child: Text(
                              user['name'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 2. TEXT TENGAH (Nama, Email, Info)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Chips Status & Posts
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Chip Post Count
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${user['posts']} Posts",
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // Chip Joined Date
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Joined: ${user['joined']}",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 3. TOMBOL AKSI (Delete & Detail)
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _deleteUser(user['id']),
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                tooltip: 'Hapus User',
                              ),
                              IconButton(
                                onPressed: () {
                                  // Navigasi ke Detail (Sama seperti onTap card)
                                  Navigator.pushNamed(
                                    context,
                                    '/admin/users/detail',
                                    arguments: user,
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_ios),
                                color: Colors.grey.shade400,
                                iconSize: 18,
                                tooltip: 'Lihat Detail',
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