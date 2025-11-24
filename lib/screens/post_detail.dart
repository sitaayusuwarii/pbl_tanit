import 'package:flutter/material.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLikedInitial;

  const PostDetailPage({super.key, required this.post, this.isLikedInitial = false});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late bool isLiked;
  late int likesCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLikedInitial;
    likesCount = widget.post['likes_count'] ?? 0;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likesCount += isLiked ? 1 : -1;
    });
  }

  void _showComments() {
    // nanti isi komentar bisa di popup atau navigasi ke halaman komentar
  }

  void _sharePost() {
    // share logic nanti
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: const Text('Postingan', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () async {
          // kalau mau refresh bisa tambahkan fetch API
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 22,
                          child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Text(
                              post['user']?['name'] ?? 'User',
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),

                            const SizedBox(height: 2),
                            Text(
                              'Petani',
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    post['description'] ?? '',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2C2C2C)),
                  ),

                  // Image
                  if (post['image_url'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],

                  // Category
                  if (post['category'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 14, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                            post['category'] ?? 'Umum',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 4),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.favorite, '$likesCount', isLiked ? Colors.red : Colors.grey[700]!, _toggleLike),
                      _buildActionButton(Icons.chat_bubble_outline, '${post['comments_count'] ?? 0}', Colors.grey[700]!, _showComments),
                      _buildActionButton(Icons.share_outlined, 'Bagikan', Colors.grey[700]!, _sharePost),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
