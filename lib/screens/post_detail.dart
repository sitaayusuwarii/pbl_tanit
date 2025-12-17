import 'dart:convert';
import 'dart:async'; // Tambahkan ini untuk Future.delayed
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLikedInitial;

  const PostDetailPage({
    super.key, 
    required this.post, 
    this.isLikedInitial = false
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late bool isLiked;
  late int likesCount;
  
  // 🔹 State & Controller
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  
  // Controller untuk Input, Scroll, dan Focus
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 
  final FocusNode _commentFocusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLikedInitial;
    likesCount = widget.post['likes_count'] ?? 0;
    _fetchComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // 🔹 Fetch Komentar dari API
  Future<void> _fetchComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final postId = widget.post['id'];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _comments = jsonDecode(response.body);
            _isLoadingComments = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingComments = false);
      }
    } catch (e) {
      print("Error fetching comments: $e");
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // 🔹 Kirim Komentar
  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final postId = widget.post['id'];

      // Kirim ke API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        FocusScope.of(context).unfocus(); // Tutup keyboard
        
        // Refresh data
        await _fetchComments(); 
        
        // Scroll ke bawah setelah UI selesai dirender
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error post comment: $e');
    }
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likesCount += isLiked ? 1 : -1;
    });
    // Tambahkan request API like di sini jika diperlukan
  }

  // ✅ PERBAIKAN: Logika Scroll saat klik tombol komentar
  void _showComments() {
    // 1. Fokus ke input agar keyboard muncul
    FocusScope.of(context).requestFocus(_commentFocusNode);
    
    // 2. Beri jeda waktu agar keyboard naik sempurna, baru scroll
    Future.delayed(const Duration(milliseconds: 600), () {
      _scrollToBottom();
    });
  }

  // Fungsi helper untuk scroll ke bawah
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sharePost() {
    // Implementasi Share
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
      
      // 🔹 Input Field di Bagian Bawah Layar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode, // Sambungkan FocusNode
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _postComment,
                icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),
      ),

      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _fetchComments,
        child: ListView(
          controller: _scrollController, // Sambungkan ScrollController
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // --- BAGIAN 1: DETAIL POSTINGAN ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header User
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
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 22,
                          child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 24),
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
                  
                  // Deskripsi
                  Text(
                    post['description'] ?? '',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2C2C2C)),
                  ),

                  // Gambar Postingan
                  if (post['image_url'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[100]),
                      ),
                    ),
                  ],

                  // Kategori Badge
                   if (post['category'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post['category'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 4),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.favorite, '$likesCount', isLiked ? Colors.red : Colors.grey[700]!, _toggleLike),
                      // Tombol Komentar memanggil _showComments
                      _buildActionButton(Icons.chat_bubble_outline, '${_comments.length}', Colors.grey[700]!, _showComments),
                      _buildActionButton(Icons.share_outlined, 'Bagikan', Colors.grey[700]!, _sharePost),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- BAGIAN 2: DAFTAR KOMENTAR ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Belum ada komentar. Jadilah yang pertama!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    // Mapping data komentar ke widget
                    ..._comments.map((comment) => _buildCommentItem(comment)),
                    
                  // Padding ekstra di bawah agar item terakhir tidak tertutup input
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tampilan Item Komentar
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: comment['user']?['profile_picture'] != null
                // Pastikan IP Address benar
                ? NetworkImage('${ApiConfig.imageUrl}/${comment['user']['profile_picture']}') 
                : null,
            child: comment['user']?['profile_picture'] == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['user']?['name'] ?? 'User',
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment['content'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 14,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                   'Baru saja', 
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ],
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