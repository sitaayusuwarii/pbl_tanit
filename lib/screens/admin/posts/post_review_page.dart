import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';

class PostReviewPage extends StatefulWidget {
  const PostReviewPage({Key? key}) : super(key: key);

  @override
  State<PostReviewPage> createState() => _PostReviewPageState();
}

class _PostReviewPageState extends State<PostReviewPage> {
  // Mock data for pending posts
  final List<Map<String, dynamic>> pendingPosts = [
    {
      'id': 1,
      'title': 'Inovasi Pertanian Vertical Farming',
      'author': 'Hendra Kusuma',
      'category': 'Teknologi Pertanian',
      'date': '2024-11-16',
      'status': 'pending',
    },
    {
      'id': 2,
      'title': 'Budidaya Ikan Lele Modern',
      'author': 'Ratna Sari',
      'category': 'Peternakan',
      'date': '2024-11-16',
      'status': 'pending',
    },
  ];

  void _approvePost(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Approve'),
        content: const Text('Apakah Anda yakin ingin menyetujui postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Postingan berhasil disetujui')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectPost(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reject'),
        content: const Text('Apakah Anda yakin ingin menolak postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Postingan ditolak')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Review Postingan'),
      drawer: const AdminSidebar(currentRoute: '/admin/posts/review'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Postingan Menunggu Review',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            if (pendingPosts.isEmpty)
              AdminCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada postingan yang menunggu review',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...pendingPosts.map((post) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PENDING',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'oleh ${post['author']} • ${post['category']} • ${post['date']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectPost(post['id']),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approvePost(post['id']),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
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
