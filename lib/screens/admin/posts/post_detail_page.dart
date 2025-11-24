import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_card.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic>? post;

  const PostDetailPage({Key? key, this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // Mock comments data
  final List<Map<String, dynamic>> comments = [
    {
      'id': 1,
      'user': 'Andi Pratama',
      'comment': 'Artikel yang sangat bermanfaat! Terima kasih sudah berbagi.',
      'date': '2024-11-15 10:30',
    },
    {
      'id': 2,
      'user': 'Dewi Lestari',
      'comment': 'Boleh tanya, berapa lama waktu yang dibutuhkan untuk panen?',
      'date': '2024-11-15 11:45',
    },
    {
      'id': 3,
      'user': 'Rudi Hermawan',
      'comment': 'Saya sudah coba tips ini dan hasilnya memuaskan!',
      'date': '2024-11-15 14:20',
    },
  ];

  void _deleteComment(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Komentar berhasil dihapus')),
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
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Detail Postingan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Details
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post?['title'] ?? 'Judul Postingan',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade600,
                        child: Text(
                          post?['author']?[0] ?? 'A',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post?['author'] ?? 'Author',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            post?['date'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          post?['category'] ?? 'Category',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'Ini adalah konten dari postingan. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text(
                        '${post?['likes'] ?? 0} likes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(Icons.comment, color: Colors.blue.shade400),
                      const SizedBox(width: 8),
                      Text(
                        '${post?['comments'] ?? 0} komentar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Comments Section
            const Text(
              'Komentar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            ...comments.map((comment) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AdminCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        comment['user'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                comment['user'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                comment['date'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment['comment'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteComment(comment['id']),
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
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