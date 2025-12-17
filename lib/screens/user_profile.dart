import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userPosts = [];

  bool _isProfileLoading = true;  // <-- loading profil
  bool _isPostsLoading = true;    // <-- loading postingan

  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserPosts();
  }

  // =====================================================
  //               FETCH USER PROFILE
  // =====================================================
 Future<void> _fetchUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  print("=== FETCH USER PROFILE ===");
  print("USER ID: ${widget.userId}");
  print("TOKEN: $token");

  try {
    final response = await http.get(
      Uri.parse('http://192.168.1.6:8000/api/users/${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _userProfile = data;
        _isFollowing = data['is_following'] ?? false;
        _followersCount = data['followers_count'] ?? 0;
        _followingCount = data['following_count'] ?? 0;
        _isProfileLoading = false;
      });
    } else {
      // <- WAJIB supaya loading berhenti kalau gagal
      setState(() => _isProfileLoading = false);
    }

  } catch (e) {
    print("ERROR FETCH PROFILE: $e");
    setState(() => _isProfileLoading = false);
  }
}


  // =====================================================
  //               FETCH USER POSTS
  // =====================================================
  Future<void> _fetchUserPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.6:8000/api/users/${widget.userId}/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _userPosts = List<Map<String, dynamic>>.from(data);
          _isPostsLoading = false;  // <-- SELESAI AMBIL POSTINGAN
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() => _isPostsLoading = false);
    }
  }

  // =====================================================
  //                   FOLLOW / UNFOLLOW
  // =====================================================
  Future<void> _toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.6:8000/api/users/${widget.userId}/follow'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _isFollowing = data['is_following'];
          _followersCount += _isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isFollowing ? "Berhasil mengikuti" : "Berhenti mengikuti"),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      print('Error toggle follow: $e');
    }
  }

  // =====================================================
  //                      BUILD UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    // LOADING PROFIL → tampil loading
    if (_isProfileLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () async {
          await _fetchUserProfile();
          await _fetchUserPosts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),

              // Jika postingan masih loading
              if (_isPostsLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )

              // Jika user tidak punya post
              else if (_userPosts.isEmpty)
                _buildEmptyPost()

              // Jika ada post
              else
                _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  //                  UI COMPONENTS
  // =====================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _userProfile?['name'] ?? 'Profil',
        style: const TextStyle(
          fontFamily: 'PublicSans',
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: _userProfile?['avatar_url'] != null
                  ? NetworkImage(
                      'http://192.168.1.6:8000/storage/${_userProfile!['avatar_url']}')
                  : null,
              child: _userProfile?['avatar_url'] == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF2E7D32))
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            _userProfile?['name'] ?? '',
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat("Postingan", _userPosts.length),
              _buildStat("Pengikut", _followersCount),
              _buildStat("Mengikuti", _followingCount),
            ],
          ),

          const SizedBox(height: 20),

          // Follow Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing
                    ? Colors.grey[200]
                    : const Color(0xFF2E7D32),
                foregroundColor:
                    _isFollowing ? Colors.black87 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isFollowing ? "Mengikuti" : "Ikuti",
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PublicSans',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPost() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada postingan',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];

        return Container(
          color: Colors.grey[100],
          child: post['image_url'] != null
              ? Image.network(
                  post['image_url'],
                  fit: BoxFit.cover,
                )
              : Center(
                  child: Text(
                    post['description'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        );
      },
    );
  }
}
