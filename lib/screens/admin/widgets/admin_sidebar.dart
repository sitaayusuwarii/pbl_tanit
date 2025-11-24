import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

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
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'T',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanitalk Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    route: '/admin/dashboard',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category_rounded,
                    title: 'Kategori',
                    route: '/admin/categories',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.article_rounded,
                    title: 'Postingan',
                    route: '/admin/posts',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'User',
                    route: '/admin/users',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Handle logout
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}
