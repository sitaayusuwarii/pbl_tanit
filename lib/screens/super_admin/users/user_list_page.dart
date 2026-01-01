import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import Admin App Bar & Sidebar
import '../../admin/widgets/admin_appbar.dart';
import '../../admin/widgets/admin_sidebar.dart';

// Import Halaman Detail User
import 'user_detail_page.dart'; 

import '../../../config/api_config.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print('Gagal load users: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetch users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 1. FILTER DATA: Pisahkan Admin/Super Admin dengan Petani
    final admins = _users.where((u) => 
        u['role'] == 'admin' || u['role'] == 'super_admin').toList();
    
    final farmers = _users.where((u) => 
        u['role'] == 'petani').toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Manajemen User'),
      drawer: const AdminSidebar(currentRoute: '/admin/users'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              color: Colors.green,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- SECTION 1: ADMIN & STAFF ---
                  if (admins.isNotEmpty) ...[
                    _buildSectionHeader("Admin & Staff", Icons.shield_outlined),
                    const SizedBox(height: 8),
                    ...admins.map((user) => _buildUserCard(user)),
                    const SizedBox(height: 24), // Jarak pemisah
                  ],

                  // --- SECTION 2: PETANI ---
                  _buildSectionHeader("Pengguna (Petani)", Icons.agriculture_outlined),
                  const SizedBox(height: 8),
                  
                  if (farmers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Belum ada data petani."),
                    )
                  else
                    ...farmers.map((user) => _buildUserCard(user)),
                ],
              ),
            ),
    );
  }

  // 🔹 WIDGET HEADER PEMISAH
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade800),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
      ],
    );
  }

  // 🔹 WIDGET KARTU USER (Refactored biar rapi)
  Widget _buildUserCard(dynamic user) {
    final avatarUrl = user['profile_picture'];
    // 🔹 LOGIKA CEK STATUS REPORT
    // Nanti pastikan backend mengirim field 'is_reported' atau 'reports_count'
    // Untuk sekarang kita anggap user dilaporkan jika 'is_reported' == true
    bool isReported = user['is_reported'] == true || (user['reports_count'] ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Jika dilaporkan, kasih border merah tipis biar kentara
        side: isReported ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              backgroundImage: avatarUrl != null
                  ? NetworkImage('${ApiConfig.baseUrl}/$avatarUrl')
                  : null,
              child: avatarUrl == null
                  ? Text(
                      user['name']?[0]?.toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Indikator merah kecil di foto jika dilaporkan
            if (isReported)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] ?? 'No Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 🔥 BADGE "DILAPORKAN"
            if (isReported) 
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      "DILAPORKAN",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? user['phone'] ?? '-'),
            const SizedBox(height: 6),
            
            // Badge Role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user['role'] == 'admin' || user['role'] == 'super_admin'
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user['role'] == 'admin' || user['role'] == 'super_admin'
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                  width: 0.5,
                ),
              ),
              child: Text(
                user['role']?.toUpperCase() ?? 'USER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: user['role'] == 'admin' || user['role'] == 'super_admin'
                      ? Colors.orange.shade800
                      : Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigasi ke Detail (Sesuai instruksi sebelumnya)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailPage(
                userId: user['id'], 
                userName: user['name'] ?? 'User',
              ),
            ),
          );
        },
      ),
    );
  }
}