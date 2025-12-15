import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../layout/main_layout.dart';
import 'cari.dart';
import 'chatbot.dart';
import 'komunitas.dart';
import 'profile.dart';
import 'upload_post.dart';
import '../config/api_config.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF2E7D32),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _posts = [];
  bool _loadingPosts = true;
  List<bool> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

 Future<void> savePost(Map<String, dynamic> post) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? savedJson = prefs.getString('saved_posts');
  List<Map<String, dynamic>> saved = savedJson != null
      ? List<Map<String, dynamic>>.from(json.decode(savedJson))
      : [];

  // Hindari duplikasi
  saved.removeWhere((p) => p['id'] == post['id']);

  saved.add({
    "id": post["id"],
    "title": post["title"],
    "description": post["description"],
    "image_url": post["image_url"],
    "category": post["category"],
    "likes_count": post["likes_count"],
    "comments_count": post["comments_count"],
    "user": {
      "name": post["user"]?["name"] ?? "User"
    }
  });

  await prefs.setString('saved_posts', json.encode(saved));
}




  Future<void> _fetchPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _posts = List<Map<String, dynamic>>.from(data);
          _likedPosts = List<bool>.filled(_posts.length, false);
        });
      } else {
        print('Gagal fetch posts: ${response.body}');
      }
    } catch (e) {
      print('Error fetch posts: $e');
    } finally {
      setState(() => _loadingPosts = false);
    }
  }

  Widget _berandaPage() {
    if (_loadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada postingan',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai berbagi cerita pertanian Anda!',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final post = _posts[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 22,
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF2E7D32),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['user'] ?? 'User',
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
                      ),
                     PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'save') {
                              savePost(post);
                            } else if (value == 'delete') {
                              _deletePost(post['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'save',
                              child: Row(
                                children: [
                                  Icon(Icons.bookmark_border,
                                      size: 20,
                                      color: Colors.green[700]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Simpan',
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red[700]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ],
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
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),

                  // Image if exists
                  if (post['image_url'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(
                                imageUrl: post['image_url'].toString(),
                              ),
                            ),
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            post['image_url'].toString(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Category Badge
                  if (post['category'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post['category'] ?? "Umum",
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
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
                      _buildActionButton(
                        icon: _likedPosts[i]
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: '${post['likes_count'] ?? 0}',
                        color: _likedPosts[i]
                            ? Colors.red
                            : Colors.grey[700]!,
                        onTap: () => _toggleLike(i, post['id']),
                      ),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${post['comments_count'] ?? 0}',
                        color: Colors.grey[700]!,
                        onTap: () => _showComments(i, post['id']),
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        label: 'Bagikan',
                        color: Colors.grey[700]!,
                        onTap: () => _sharePost(post),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(int index, int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _likedPosts[index] = data['liked'];
        _posts[index]['likes_count'] = data['likes_count'];
      });
    } else {
      print('Gagal like post: ${response.body}');
    }
  }

void _showComments(int index, int postId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final TextEditingController commentController = TextEditingController();

  // 1. Ambil semua komentar awal (Data Initial)
  List initialComments = []; 
  try {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      initialComments = jsonDecode(res.body);
    } else {
      print('Gagal load komentar: ${res.body}');
    }
  } catch (e) {
    print('Error fetch komentar: $e');
  }

  // 🔹 Tampilkan modal komentar
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      // Deklarasi list yang bisa diubah di scope ini
      List comments = initialComments; 

      return StatefulBuilder(
        builder: (context, setStateModal) {
          final ScrollController scrollController = ScrollController();

          // Fungsi untuk scroll ke bawah otomatis
          void _scrollToBottom() {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
          
          // Panggil scroll ke bawah setelah build awal (jika sudah ada komentar)
          if (comments.isNotEmpty) {
             WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }

          // DEBUGGING: Tambahkan print untuk memastikan list tidak kosong
          print('DEBUG: Jumlah komentar yang dirender: ${comments.length}');
          // ---

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Komentar',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 Daftar komentar
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada komentar',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    // Pastikan path image benar dan server berjalan
                                    backgroundImage: c['user']?['profile_picture'] != null
                                        ? NetworkImage(
                                            'http://192.168.1.11:8000/storage/${c['user']['profile_picture']}')
                                        : const AssetImage('assets/images/default_profile.png')
                                            as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "${c['user']?['name'] ?? 'User'} ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontFamily: 'PublicSans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: c['content'] ?? 'Isi Komentar Hilang', // Fallback
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontFamily: 'PublicSans',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          // Sebaiknya gunakan c['created_at'] dan format waktu
                                          'Baru saja', 
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                            fontFamily: 'PublicSans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // 🔹 Input komentar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar...',
                          hintStyle: TextStyle(
                            fontFamily: 'PublicSans',
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;

                        try {
                          final response = await http.post(
                            Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({'content': text}), 
                          );

                          if (response.statusCode == 200) {
                            final newComment = jsonDecode(response.body);

                            setStateModal(() {
                              // Menggunakan spread operator untuk memastikan rebuild
                              comments = [...comments, newComment]; 
                              commentController.clear();
                            });

                            FocusScope.of(context).unfocus(); 

                            await Future.delayed(const Duration(milliseconds: 100));
                            _scrollToBottom();
                          } else {
                            print('Gagal kirim komentar: ${response.body}');
                          }
                        } catch (e) {
                          print('Error kirim komentar: $e');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}






  void _sharePost(Map<String, dynamic> post) {
    final text = '${post['user'] ?? 'User'}: ${post['description'] ?? ''}';
    Share.share(text, subject: 'Bagikan Postingan dari TaniTalk');
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Buat Postingan',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildPostOption(
                icon: Icons.image_outlined,
                title: 'Unggah Foto',
                subtitle: 'Bagikan gambar dari galeri',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 12),
              _buildPostOption(
                icon: Icons.edit_outlined,
                title: 'Tulis Postingan',
                subtitle: 'Bagikan pemikiran Anda',
                onTap: () {
                  Navigator.pop(context);
                  _showTextPostSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadPostScreen(imageBytes: bytes),
      ),
    );

    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 800));
      _fetchPosts();
    }
  }

  void _showTextPostSheet() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                maxLines: 6,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Apa yang ingin Anda bagikan?',
                  hintStyle: TextStyle(
                    fontFamily: 'PublicSans',
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';

                    final response = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/posts'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({'description': text}),
                    );

                    if (response.statusCode == 200) {
                      textController.clear();
                      Navigator.of(context).pop();
                      _fetchPosts();
                    } else {
                      print('Gagal post teks: ${response.body}');
                    }
                  },
                  child: const Text(
                    'Posting',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _fetchPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postingan berhasil dihapus'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } else {
      print('Gagal hapus post: ${response.body}');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _berandaPage(),
      const CariPage(),
      const ChatbotPage(),
      const KomunitasPage(),
      const ProfilePage(),
    ];

    return MainLayout(
      child: _pages[_selectedIndex],
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      onAddPressed: _showPostOptions,
    );
  }
}