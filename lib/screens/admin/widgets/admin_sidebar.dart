import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORT PAGE YANG DIBUTUHKAN
import '../../login.dart';
import '../../admin/dashboard/admin_dashboard.dart';
import '../../admin/categories/category_list_page.dart'; 
import '../../admin/posts/post_list_page.dart'; 
import '../../home.dart';

// IMPORT KHUSUS SUPER ADMIN
import '../../super_admin/users/user_list_page.dart';


class AdminSidebar extends StatefulWidget {
  final String currentRoute;

  const AdminSidebar({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  String _role = '';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 Ambil Role & Nama dari Shared Preferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'admin';
      _name = prefs.getString('name') ?? 'Admin';
    });
  }

  // 🔹 Fungsi Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus Token & Role
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade800,
              Colors.green.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            // --- HEADER DRAWER ---
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: SizedBox(
                width: double.infinity, // Agar rata tengah sempurna
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _role == 'super_admin' ? 'Super Administrator' : 'Admin Staff',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- LIST MENU ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  // 1. DASHBOARD (Semua Admin)
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    isActive: widget.currentRoute == '/admin/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const AdminDashboard())
                      );
                    },
                  ),

                  // 2. KATEGORI (Semua Admin)
                  _buildMenuItem(
                    context,
                    icon: Icons.category_rounded,
                    title: 'Kategori',
                    isActive: widget.currentRoute == '/admin/categories',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoryListPage()));
                    },
                  ),

                  // 3. HOME PAGE (Semua Admin)
                  _buildMenuItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Posting',
                    isActive: widget.currentRoute == '/home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const HomeScreen())
                      );
                    },
                  ),

                  // 3. POSTINGAN (Semua Admin)
                  _buildMenuItem(
                    context,
                    icon: Icons.article_rounded,
                    title: 'Manajemen Postingan',
                    isActive: widget.currentRoute == '/admin/posts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PostListPage()));
                    },
                  ),

                  // --- KHUSUS SUPER ADMIN ---
                  if (_role == 'super_admin') ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24, thickness: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        "SUPER ADMIN",
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // 4. MANAJEMEN USER (Hanya Super Admin)
                    _buildMenuItem(
                      context,
                      icon: Icons.people_rounded,
                      title: 'Manajemen User', // Ini mengarah ke User List
                      isActive: widget.currentRoute == '/admin/users',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (_) => const UserListPage())
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // --- LOGOUT BUTTON ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                hoverColor: Colors.red.withOpacity(0.1),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Item Menu yang sudah dimodifikasi untuk menerima onTap
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // Highlight jika menu sedang aktif
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: Colors.white30) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}