import 'package:flutter/material.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Map<String, dynamic> stats = {
    'totalUsers': 245,
    'totalPosts': 1432,
    'totalCategories': 12,
    'totalComments': 3210,
  };

  final List<Map<String, dynamic>> recentPosts = [
    {
      'id': 1,
      'title': 'Tips Menanam Padi di Musim Kemarau',
      'author': 'Budi Santoso',
      'date': '2024-11-15',
    },
    {
      'id': 2,
      'title': 'Cara Merawat Tanaman Cabai',
      'author': 'Siti Aminah',
      'date': '2024-11-14',
    },
    {
      'id': 3,
      'title': 'Teknologi Drone untuk Pertanian',
      'author': 'Ahmad Wijaya',
      'date': '2024-11-13',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const AdminAppBar(title: 'Dashboard'),
      drawer: const AdminSidebar(currentRoute: '/admin/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // --- LIST STAT CARDS (Memanjang) ---
            _statCard(
              title: "Total User",
              value: stats['totalUsers'].toString(),
              icon: Icons.people,
              bgColor: Colors.blue.shade50,
              iconColor: Colors.blue,
            ),
            _statCard(
              title: "Total Postingan",
              value: stats['totalPosts'].toString(),
              icon: Icons.article,
              bgColor: Colors.green.shade50,
              iconColor: Colors.green,
            ),
            _statCard(
              title: "Total Kategori",
              value: stats['totalCategories'].toString(),
              icon: Icons.category,
              bgColor: Colors.purple.shade50,
              iconColor: Colors.purple,
            ),
            _statCard(
              title: "Total Komentar",
              value: stats['totalComments'].toString(),
              icon: Icons.comment,
              bgColor: Colors.orange.shade50,
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 30),

            // --- Postingan Terbaru ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        "Postingan Terbaru",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ...recentPosts.map((post) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.green.shade700,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "oleh ${post['author']} • ${post['date']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KARTU STATISTIK MEMANJANG ---
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(icon, size: 40, color: iconColor),
        ],
      ),
    );
  }
}
