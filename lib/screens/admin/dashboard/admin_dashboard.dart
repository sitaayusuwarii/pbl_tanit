import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_sidebar.dart';
import '../../../services/dashboard_service.dart';
import '../../../config/api_config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic> stats = {
    'totalUsers': 0,
    'totalPosts': 0,
    'totalCategories': 0,
    'totalComments': 0,
  };

  List<dynamic> recentPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _dashboardService.getStats(),
        _dashboardService.getRecentPosts(),
      ]);

      if (mounted) {
        setState(() {
          stats = results[0] as Map<String, dynamic>;
          recentPosts = results[1] as List<dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error dashboard: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Helper formatting tanggal biar rapi (Opsional)
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
      appBar: const AdminAppBar(title: 'Dashboard Overview'),
      drawer: const AdminSidebar(currentRoute: '/admin/dashboard'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                    // --- STAT CARDS ---
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

                    // --- RECENT POSTS SECTION ---
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

                          if (recentPosts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Belum ada postingan terbaru."),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentPosts.length,
                              itemBuilder: (context, index) {
                                final post = recentPosts[index];

                                // 🔥🔥🔥 BAGIAN PERBAIKAN UTAMA 🔥🔥🔥
                                // 1. Parsing Nama Author dengan Aman (Anti Error String vs Map)
                                String authorName = 'Unknown';
                                if (post['user'] is Map) {
                                  authorName = post['user']['name'] ?? 'Unknown';
                                } else if (post['user'] is String) {
                                  authorName = post['user'];
                                }

                                // 2. Parsing Judul (Deskripsi)
                                final rawTitle = post['description'] ?? post['title'] ?? 'Tanpa Judul';
                                final displayTitle = rawTitle.length > 30 
                                    ? '${rawTitle.substring(0, 30)}...' 
                                    : rawTitle;

                                // 3. Format Tanggal
                                String date = _formatDate(post['created_at']);

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
                                        displayTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "oleh $authorName • $date", // Gunakan variabel authorName yang sudah diproses
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

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