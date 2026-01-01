import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 

import '../../admin/widgets/admin_appbar.dart';
import '../../admin/widgets/admin_card.dart';
import '../../../config/api_config.dart'; 

class UserDetailPage extends StatefulWidget {
  final int userId; 
  final String userName; 
  
  const UserDetailPage({
    Key? key,
    required this.userId,
    this.userName = 'Detail User',
  }) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<dynamic> _userPosts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDetail();
  }

  // Fungsi Fetch Data dari API
  Future<void> _fetchUserDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // URL Endpoint
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/${widget.userId}');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          // Backend mengirim struktur: { "user": {...}, "posts": [...] }
          _userData = data['user']; 
          _userPosts = data['posts'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print("Error fetching user detail: $e");
    }
  }

  // Helper Format Tanggal (Hanya dipakai untuk postingan)
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Detail User'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text("Terjadi Kesalahan:\n$_errorMessage", textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUserDetail,
                        child: const Text("Coba Lagi"),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KARTU PROFIL USER ---
                      AdminCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green.shade600,
                              backgroundImage: _userData?['profile_picture'] != null
                                  ? NetworkImage('${ApiConfig.baseUrl}/${_userData!['profile_picture']}')
                                  : null,
                              child: _userData?['profile_picture'] == null
                                  ? Text(
                                      _userData?['name']?[0]?.toUpperCase() ?? 'U',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userData?['name'] ?? 'User Name',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userData?['email'] ?? '-',
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
                                          _userData?['role']?.toUpperCase() ?? 'USER',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 🔥 PERBAIKAN DI SINI: Gunakan key 'joined' dari backend
                                      Text(
                                        'Bergabung: ${_userData?['joined'] ?? '-'}', 
                                        style: TextStyle(
                                          fontSize: 12,
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
                      
                      // --- STATISTIK USER ---
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.article_rounded,
                              color: Colors.blue.shade600,
                              // Ambil posts_count dari backend
                              value: (_userData?['posts_count'] ?? _userPosts.length).toString(),
                              label: 'Total Postingan',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.favorite,
                              color: Colors.red.shade400,
                              // Ambil likes_received_count dari backend
                              value: (_userData?['likes_received_count'] ?? 0).toString(),
                              label: 'Total Likes',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.comment,
                              color: Colors.orange.shade600,
                              // Ambil comments_count dari backend
                              value: (_userData?['comments_count'] ?? 0).toString(),
                              label: 'Komentar',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // --- RIWAYAT POSTINGAN ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Riwayat Postingan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_userPosts.length} Post",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_userPosts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text("Belum ada postingan", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      else
                        ..._userPosts.map((post) => _buildPostItem(post)),
                    ],
                  ),
                ),
    );
  }

  // Widget Item Statistik
  Widget _buildStatItem({required IconData icon, required Color color, required String value, required String label}) {
    return AdminCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget Item Postingan
  Widget _buildPostItem(Map<String, dynamic> post) {
    // Parsing judul aman (jika title null, pakai description)
    String title = post['title'] ?? post['description'] ?? 'Tanpa Judul';
    if (title.length > 50) title = "${title.substring(0, 50)}...";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
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
                Text('${post['likes_count'] ?? 0}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.blue.shade400),
                const SizedBox(width: 4),
                Text('${post['comments_count'] ?? 0}'),
                const Spacer(),
                Text(
                  _formatDate(post['created_at']), // Format tanggal postingan
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}