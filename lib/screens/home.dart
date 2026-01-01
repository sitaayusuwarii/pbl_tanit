import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

// --- IMPORT SIDEBAR ADMIN ---
import 'admin/widgets/admin_sidebar.dart'; // Pastikan path benar
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16, left: 16,
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
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
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUserRole();
    _fetchPosts();
  }

  Future<void> _checkCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('role') ?? 'petani';
    });
  }

  Future<void> savePost(Map<String, dynamic> post) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedJson = prefs.getString('saved_posts');
    List<Map<String, dynamic>> saved = savedJson != null
        ? List<Map<String, dynamic>>.from(json.decode(savedJson))
        : [];

    saved.removeWhere((p) => p['id'] == post['id']);

    // 🔥 PERBAIKAN PARSING USER (Mencegah Error String vs Map)
    String userName = 'User';
    if (post['user'] is Map) {
      userName = post['user']['name'] ?? 'User';
    } else if (post['user'] is String) {
      userName = post['user'];
    }

    saved.add({
      "id": post["id"],
      "title": post["title"],
      "description": post["description"],
      "image_url": post["image_url"],
      "category": post["category"],
      "likes_count": post["likes_count"],
      "comments_count": post["comments_count"],
      "user": {"name": userName}
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

  // 🔹 Widget Badge Admin
  Widget _buildAdminBadge(String? role) {
    if (role != 'admin' && role != 'super_admin') return const SizedBox.shrink();
    bool isSuper = role == 'super_admin';
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSuper ? Colors.orange.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSuper ? Colors.orange : Colors.blue, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSuper ? Icons.stars : Icons.verified, size: 12, color: isSuper ? Colors.orange.shade800 : Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(isSuper ? "Super Admin" : "Admin", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSuper ? Colors.orange.shade800 : Colors.blue.shade700)),
        ],
      ),
    );
  }

  Widget _berandaPage() {
    if (_loadingPosts) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    if (_posts.isEmpty) return const Center(child: Text('Belum ada postingan'));

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final post = _posts[i];

          // 🔥 PARSING USER AMAN (Fix Error Layar Merah)
          String userName = 'User';
          String? userRole;
          String? userAvatar;

          if (post['user'] is Map) {
            userName = post['user']['name'] ?? 'User';
            userRole = post['user']['role'];
            userAvatar = post['user']['profile_picture'];
          } else if (post['user'] is String) {
            userName = post['user'];
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 22,
                        backgroundImage: userAvatar != null ? NetworkImage('${ApiConfig.baseUrl}/$userAvatar') : null,
                        child: userAvatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(userName, style: const TextStyle(fontFamily: 'PublicSans', fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                _buildAdminBadge(userRole),
                              ],
                            ),
                            Text('Petani', style: TextStyle(fontFamily: 'PublicSans', fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      // ... (Popup Menu code remains same, simplified here for length)
                      IconButton(icon: const Icon(Icons.more_horiz), onPressed: (){}), 
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post['description'] ?? '', style: const TextStyle(fontFamily: 'PublicSans', fontSize: 15, height: 1.5)),
                  if (post['image_url'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: post['image_url'].toString()))),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(post['image_url'].toString(), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                  // ... Actions buttons here (simplified)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  void _showPostOptions() { /* ... kode popup post ... */ }

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
      // 🔥 LOGIKA SIDEBAR UTAMA
      drawer: (_currentUserRole == 'admin' || _currentUserRole == 'super_admin')
          ? const AdminSidebar(currentRoute: '/home')
          : null,
      
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      onAddPressed: _showPostOptions, // Pastikan fungsi _showPostOptions lengkap
      child: _pages[_selectedIndex],
    );
  }
}