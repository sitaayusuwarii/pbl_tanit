import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_card.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const UserDetailPage({Key? key, this.user}) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  // Mock user posts
  final List<Map<String, dynamic>> userPosts = [
    {
      'id': 1,
      'title': 'Tips Menanam Padi di Musim Kemarau',
      'likes': 45,
      'comments': 12,
      'date': '2024-11-15',
    },
    {
      'id': 2,
      'title': 'Cara Merawat Tanaman Cabai Agar Hasil Maksimal',
      'likes': 38,
      'comments': 8,
      'date': '2024-11-10',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Detail User'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            AdminCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade600,
                    child: Text(
                      user?['name']?[0] ?? 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['email'] ?? 'email@example.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?['status']?.toUpperCase() ?? 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Bergabung: ${user?['joined'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistics
            Row(
              children: [
                Expanded(
                  child: AdminCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.article_rounded,
                          size: 40,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?['posts']?.toString() ?? '0',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Postingan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AdminCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 40,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '342',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Likes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AdminCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 40,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '89',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Komentar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // User Posts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Postingan User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...userPosts.map((post) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text('${post['likes']}'),
                        const SizedBox(width: 16),
                        Icon(Icons.comment, size: 16, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Text('${post['comments']}'),
                        const SizedBox(width: 16),
                        Text(
                          post['date'],
                          style: TextStyle(color: Colors.grey.shade600),
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
