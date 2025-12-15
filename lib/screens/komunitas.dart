import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class KomunitasPage extends StatefulWidget {
  const KomunitasPage({super.key});

  @override
  State<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends State<KomunitasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  List<Map<String, dynamic>> _allCommunities = [];
  List<Map<String, dynamic>> _myCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommunities() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Fetch all communities
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/communities'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allCommunities = List<Map<String, dynamic>>.from(data);
          // Filter my communities (where user is member or owner)
          _myCommunities = _allCommunities
              .where((c) => c['is_member'] == true || c['is_owner'] == true)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetch communities: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinCommunity(int communityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/communities/$communityId/join'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Berhasil bergabung dengan komunitas'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _fetchCommunities();
      }
    } catch (e) {
      print('Error join community: $e');
    }
  }

  Future<void> _leaveCommunity(int communityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/communities/$communityId/leave'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Anda keluar dari komunitas'),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _fetchCommunities();
      }
    } catch (e) {
      print('Error leave community: $e');
    }
  }

  void _showCreateCommunityDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Padi';

    final categories = [
      {'name': 'Padi', 'icon': '🌾'},
      {'name': 'Kopi', 'icon': '☕'},
      {'name': 'Cokelat', 'icon': '🍫'},
      {'name': 'Jagung', 'icon': '🌽'},
      {'name': 'Sayuran', 'icon': '🥬'},
      {'name': 'Buah-buahan', 'icon': '🍎'},
      {'name': 'Umum', 'icon': '🌱'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Buat Komunitas Baru',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Komunitas',
                  hintText: 'Contoh: Petani Padi Indonesia',
                  prefixIcon: const Icon(Icons.groups, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Ceritakan tentang komunitas Anda...',
                  prefixIcon: const Icon(Icons.description, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kategori',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedCategory = cat['name'] as String;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat['icon'] as String, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
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
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama komunitas harus diisi')),
                      );
                      return;
                    }

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token') ?? '';

                      final response = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/communities'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'category': selectedCategory,
                        }),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Komunitas berhasil dibuat!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        _fetchCommunities();
                      }
                    } catch (e) {
                      print('Error create community: $e');
                    }
                  },
                  child: const Text(
                    'Buat Komunitas',
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
        ),
      ),
    );
  }

  void _showCommunityDetail(Map<String, dynamic> community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailPage(community: community),
      ),
    ).then((_) => _fetchCommunities());
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    final isMember = community['is_member'] == true;
    final isOwner = community['is_owner'] == true;

    return GestureDetector(
      onTap: () => _showCommunityDetail(community),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                community['name'] ?? 'Komunitas',
                                style: const TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${community['members_count'] ?? 0} anggota',
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
                  ),
                ],
              ),
              if (community['description'] != null &&
                  community['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  community['description'],
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (community['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        community['category'],
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!isOwner)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {
                          if (isMember) {
                            _leaveCommunity(community['id']);
                          } else {
                            _joinCommunity(community['id']);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isMember
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                          foregroundColor: isMember
                              ? const Color(0xFF2E7D32)
                              : Colors.white,
                          side: BorderSide(
                            color: const Color(0xFF2E7D32),
                            width: isMember ? 1.5 : 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          isMember ? 'Keluar' : 'Gabung',
                          style: const TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komunitas',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      IconButton(
                        onPressed: _showCreateCommunityDialog,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF2E7D32),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Jelajahi'),
                    Tab(text: 'Komunitas Saya'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Jelajahi
                      RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _fetchCommunities,
                        child: _allCommunities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.groups_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada komunitas',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Buat komunitas pertama Anda!',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _allCommunities.length,
                                itemBuilder: (context, index) {
                                  return _buildCommunityCard(
                                      _allCommunities[index]);
                                },
                              ),
                      ),
                      // Tab Komunitas Saya
                      RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _fetchCommunities,
                        child: _myCommunities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group_add_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada komunitas',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gabung atau buat komunitas!',
                                      style: TextStyle(
                                        fontFamily: 'PublicSans',
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _myCommunities.length,
                                itemBuilder: (context, index) {
                                  return _buildCommunityCard(
                                      _myCommunities[index]);
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Community Detail Page
class CommunityDetailPage extends StatelessWidget {
  final Map<String, dynamic> community;

  const CommunityDetailPage({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Komunitas',
          style: TextStyle(
            fontFamily: 'PublicSans',
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Color(0xFF2E7D32),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    community['name'] ?? 'Komunitas',
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${community['members_count'] ?? 0} anggota',
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tentang Komunitas',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    community['description'] ?? 'Tidak ada deskripsi',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (community['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            community['category'],
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}