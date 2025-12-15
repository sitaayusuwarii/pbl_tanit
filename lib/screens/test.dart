import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile.dart';
import 'post_detail.dart';
import 'image_viewer.dart'; 
import 'saved_post_page.dart';
import '../config/api_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
  setState(() => _loading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Ambil data user
    final userResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    // Ambil postingan user (my-posts)
    final postsResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/my-posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (userResponse.statusCode == 200) {
      final decodedUser = jsonDecode(userResponse.body);
      final decodedPosts = jsonDecode(postsResponse.body);

      setState(() {
        // Simpan data user (kalau hasilnya { "id":1, "name":"..." } langsung aja)
        _userData = decodedUser is Map<String, dynamic> && decodedUser.containsKey('user')
            ? decodedUser['user']
            : decodedUser;

        // Simpan postingan user (pastikan field dari Laravel-nya sesuai)
        if (postsResponse.statusCode == 200 && decodedPosts['success'] == true) {
          _userPosts = List<Map<String, dynamic>>.from(decodedPosts['posts']);
        } else {
          _userPosts = [];
        }
      });
    }
  } catch (e) {
    print('Error fetch profile: $e');
  } finally {
    setState(() => _loading = false);
  }
}

  

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontFamily: 'PublicSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'PublicSans',
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

 

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text(
                  'Tersimpan',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                 onTap: () {
                  Navigator.pop(context); // Tutup bottomsheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedPostsPage(),
                    ),
                  );
                },
              ),  
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text(
                  'Aktivitas Anda',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[600]),
                title: Text(
                  'Keluar',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              title: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    _userData['name'] ?? 'Username',
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.black),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: _showOptionsMenu,
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          color: const Color(0xFF2E7D32),
          onRefresh: _fetchUserProfile,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Row(
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: () async {
                              final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                // Upload avatar
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: _userData['avatar_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(40),
                                        child: Image.network(
                                          _userData['avatar_url'],
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Color(0xFF2E7D32),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Stats
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat('${_userPosts.length}', 'Postingan'),
                                _buildStat('${_userData['koneksi_count'] ?? 0}', 'Koneksi'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name & Bio
                      Text(
                        _userData['name'] ?? 'User',
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_userData['bio'] != null &&
                          _userData['bio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _userData['bio'],
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (_userData['location'] != null &&
                          _userData['location'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _userData['location'],
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfilePage(userData: _userData),
                                    ),
                                  );

                                  // ✅ Jika halaman edit mengembalikan "true", refresh profil
                                  if (result == true) {
                                    _fetchUserProfile();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                ),
                              ),
                            ),


                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Bagikan Profile',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.black,
                    indicatorWeight: 1,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on, size: 24)),
                    ],
                  ),
                ),
              ),
              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Grid Posts
                    _userPosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Postingan',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bagikan foto pertama Anda',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
  padding: const EdgeInsets.all(2),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 2,
    crossAxisSpacing: 2,
    childAspectRatio: 1,
  ),
  itemCount: _userPosts.length,
  itemBuilder: (context, index) {
    final post = _userPosts[index];
    return GestureDetector(
     onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PostDetailPage(post: post),
    ),
  );
},


      child: Container(
        color: Colors.grey[200],
        child: post['image_url'] != null && post['image_url'].toString().isNotEmpty
            ? Image.network(
                post['image_url'].toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.article,
                  color: Color(0xFF2E7D32),
                  size: 32,
                ),
              ),
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

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCircle({
    required String label,
    required IconData icon,
    bool isAdd = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isAdd ? Colors.grey[300]! : const Color(0xFF2E7D32),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isAdd ? Colors.grey[600] : const Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12,
            ),
          ),
        ], 
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}