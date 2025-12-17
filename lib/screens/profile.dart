import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_tanit/screens/detail_post.dart';
import 'package:pbl_tanit/screens/edit_profile.dart';
import 'package:pbl_tanit/screens/saved_post_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ProfilePage extends StatefulWidget {
  final int? userId; // Null jika profile sendiri

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> userPosts = [];
  int? currentUserId;
  bool isOwnProfile = false;
  bool isFollowing = false;

  bool isLoading = true;
  bool isLoadingPosts = false;
  late TabController _tabController;

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 1, vsync: this);
  loadCurrentUser();  
  fetchUserProfile();
  fetchUserPosts();
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String getPostImageUrl(Map<String, dynamic> post) {
  final img = post['image_url'] ?? post['image'];

  if (img == null || img.toString().isEmpty) return '';

  final imgStr = img.toString();

  if (imgStr.startsWith("http")) {
    return imgStr;
  }

  return fixLaravelImagePath(imgStr);
}




Future<void> loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  currentUserId = prefs.getInt('user_id'); // pastikan kamu menyimpan id saat login

  // Profil sendiri = jika widget.userId itu null ATAU sama dengan id yang login
  isOwnProfile = (widget.userId == null || widget.userId == currentUserId);

  setState(() {});
}

String getAvatarUrl() {
  final avatar = userProfile?['avatar_url'];

  if (avatar == null || avatar.toString().isEmpty) {
    return 'https://ui-avatars.com/api/?name=${userProfile?['name']}&background=10b981&color=fff';
  }

  final a = avatar.toString();

  if (a.startsWith("http")) {
    return a;
  }

  return fixLaravelImagePath(a);
}



  // Fetch user profile
 Future<void> fetchUserProfile() async {
  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = widget.userId != null
        ? '${AppConfig.baseUrl}/user/${widget.userId}'
        : '${AppConfig.baseUrl}/user';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        // Jika API mengirim: { "user": {...} }
        if (decoded.containsKey('user')) {
        userProfile = decoded['user'];
      } 
      else if (decoded.containsKey('data')) {
        userProfile = decoded['data'];
      }
      else if (decoded.containsKey('success') && decoded['data'] != null) {
        userProfile = decoded['data'];
      }
      else if (decoded is List && decoded.isNotEmpty) {
        userProfile = decoded[0];
      }
      else {
        userProfile = decoded;
      }

    if (decoded.containsKey('is_following')) {
    isFollowing = decoded['is_following'];
  }

      });
    }
  } catch (e) {
    print('Error fetchUserProfile: $e');
  } finally {
    setState(() => isLoading = false);
  }
}


  // Fetch user posts
 Future<void> fetchUserPosts() async {
  try {
    setState(() => isLoadingPosts = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // URL untuk postingan user sendiri atau user lain
    final url = widget.userId != null
        ? '${AppConfig.baseUrl}/users/${widget.userId}/posts'
        : '${AppConfig.baseUrl}/my-posts';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        // Jika struktur API nya: { "success": true, "posts": [...] }
        if (decoded is Map && decoded.containsKey('posts')) {
          userPosts = List<Map<String, dynamic>>.from(decoded['posts']);
        } else {
          userPosts = [];
        }
      });
    }
  } catch (e) {
    print('Error fetchUserPosts: $e');
  } finally {
    setState(() => isLoadingPosts = false);
  }
}

Future<void> toggleFollow() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/users/${widget.userId}/follow'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      isFollowing = !isFollowing;

      // update followers_count
      int currentFollowers = userProfile?['followers_count'] ?? 0;
      if (isFollowing) {
        userProfile?['followers_count'] = currentFollowers + 1;
      } else {
        userProfile?['followers_count'] = (currentFollowers > 0 ? currentFollowers - 1 : 0);
      }
    });
  }
}


Future<void> addNewPost(Map<String, dynamic> newPost) async {
  setState(() {
    userPosts.insert(0, newPost); // tambahkan post baru di awal list
    userProfile?['following_count'] =
        (userProfile?['following_count'] ?? 0) + 1; // update jumlah post
  });
}



  // Navigate to saved posts
  void navigateToSavedPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedPostsPage()),
    );
  }

  // Handle logout
 Future<void> handleLogout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keluar'),
      content: const Text('Apakah Anda yakin ingin keluar?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Keluar',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Arahkan ke halaman login
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}


  // Navigate to post detail
  void navigateToPostDetail(Map<String, dynamic> post) {
    final fixedPost = Map<String, dynamic>.from(post);
    
    if (fixedPost['user'] == null && userProfile != null) {
    fixedPost['user'] = {
      'id': currentUserId,
      'name': userProfile!['name'],
      'avatar_url': userProfile!['avatar_url'],
      'is_following': false,
    };
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailPostPage(
        post: post,
        currentUserId: currentUserId,
        likedPostIds: userPosts
            .where((p) => p['is_liked'] == true)
            .map<int>((p) => p['id'] as int)
            .toSet(),
        onLikeToggle: (postId) {
          final index = userPosts.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            setState(() {
              userPosts[index]['is_liked'] =
                  !(userPosts[index]['is_liked'] ?? false);
              userPosts[index]['likes_count'] =
                  (userPosts[index]['likes_count'] ?? 0) +
                      (userPosts[index]['is_liked'] ? 1 : -1);
            });
          }
        },
      ),
    ),
  );
}


 String fixLaravelImagePath(String img) {
  if (img.startsWith("http")) return img;

  // Hapus slash awal jika ada
  if (img.startsWith("/")) {
    img = img.substring(1);
  }

  // Kalau tidak mengandung storage/, tambahkan
  if (!img.startsWith("storage/")) {
    img = "storage/$img";
  }

  return "${AppConfig.baseUrl.replaceAll('/api', '')}/$img";
}



  // Handle like post
  Future<void> handleLike(int postId, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.post(
        
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userPosts[index]['is_liked'] = !userPosts[index]['is_liked'];
          userPosts[index]['likes_count'] = data['likes_count'];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }


String getAvatarFromPost(Map user) {
  final avatar = user["avatar_url"];

  // Jika avatar user POST tidak ada → pakai avatar profile utama
  if (avatar == null || avatar.toString().isEmpty) {
    return getAvatarUrl(); // ← ini ambil foto dari userProfile
  }

  final a = avatar.toString();

  if (a.startsWith("http")) {
    return a;
  }

  return fixLaravelImagePath(a);
}




  // Build single post item (Twitter style)
 Widget _buildPostItem(Map<String, dynamic> post) {
  final user = post["user"] ?? {}; // <-- aman, tidak null
  final avatarUrl = getAvatarFromPost(user);

  return InkWell(
    onTap: () => navigateToPostDetail(post),
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
          radius: 24,
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.green)
              : null,
        ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    Text(
                      (user["name"] ?? userProfile?['name'] ?? ""),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${user["username"] ?? userProfile?['username'] ?? ""} · ${post["created_at"] ?? ""}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Caption
                if ((post["caption"] ?? "").toString().isNotEmpty)
                  Text(
                    post["caption"],
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),

                // IMAGE
                if (post["image"] != null || post["image_url"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                getPostImageUrl(post),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),

                const SizedBox(height: 12),

                // ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Comment
                    InkWell(
                      onTap: () => navigateToPostDetail(post),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${post["comments_count"] ?? 0}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // Retweet
                    // Row(
                    //   children: [
                    //     Icon(Icons.repeat, size: 18, color: Colors.grey[600]),
                    //     const SizedBox(width: 6),
                    //     Text(
                    //       '${post["shares_count"] ?? 0}',
                    //       style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    //     ),
                    //   ],
                    // ),

                    // Like
                    InkWell(
                      onTap: () {
                        final index = userPosts.indexOf(post);
                        handleLike(post['id'], index);
                      },
                      child: Row(
                        children: [
                          Icon(
                            post["is_liked"] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: post["is_liked"] == true
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post["likes_count"] ?? 0}',
                            style: TextStyle(
                              color: post["is_liked"] == true
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Views
                    Row(
                      children: [
                        Icon(Icons.bar_chart,
                            size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${post["views_count"] ?? 0}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),

                    // Bookmark & Share
                    Row(
                      children: [
                        Icon(Icons.bookmark_border,
                            size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 16),
                        Icon(Icons.share_outlined,
                            size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,

  // BACK SELALU DI KIRI
  leading: !isOwnProfile
      ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        )
      : null,

  // JUDUL DI TENGAH / KIRI
  title: Text(
    userProfile?['name'] ?? 'Profile',
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    overflow: TextOverflow.ellipsis,
  ),

  centerTitle: true, // opsional

  // TITIK 3 DI KANAN (ACTIONS)
  actions: [
    if (isOwnProfile)
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black),
        onSelected: (value) async {
          if (value == 'saved') navigateToSavedPosts();
          if (value == 'logout') await handleLogout();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'saved',
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 20),
                SizedBox(width: 12),
                Text('Postingan Tersimpan'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Keluar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
  ],

  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(2),
    child: Container(height: 2, color: Colors.grey[300]),
  ),
),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : CustomScrollView(
              slivers: [
                // AppBar with menu
              //  SliverAppBar(
              //     backgroundColor: Colors.white,
              //     elevation: 0,
              //     pinned: true,
              //     leading: null,
              //     title: const Text(
              //       'Profile',
              //       style: TextStyle(
              //         color: Colors.black,
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //     centerTitle: true,
              //      bottom: PreferredSize(
              //       preferredSize: Size.fromHeight(1),
              //       child: Container(
              //         color: Colors.grey.shade300, // Warna garis
              //         height: 2, // Ketebalan garis
              //       ),
              //     ),

   
              //     actions: [
              //       if (isOwnProfile)
              //         PopupMenuButton<String>(
              //           icon: const Icon(Icons.more_vert, color: Colors.black),
              //           onSelected: (value) async {
              //             if (value == 'saved') {
              //               navigateToSavedPosts();
              //             } else if (value == 'logout') {
              //               await handleLogout();
              //             }
              //           },
              //           itemBuilder: (context) => [
              //             const PopupMenuItem<String>(
              //               value: 'saved',
              //               child: Row(
              //                 children: [
              //                   Icon(Icons.bookmark, size: 20),
              //                   SizedBox(width: 12),
              //                   Text('Postingan Tersimpan'),
              //                 ],
              //               ),
              //             ),
              //             const PopupMenuDivider(),
              //             const PopupMenuItem<String>(
              //               value: 'logout',
              //               child: Row(
              //                 children: [
              //                   Icon(Icons.logout, size: 20, color: Colors.red),
              //                   SizedBox(width: 12),
              //                   Text(
              //                     'Keluar',
              //                     style: TextStyle(color: Colors.red),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //     ],

              //   ),

                // Profile Header
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      

                      // Profile Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Avatar
    Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(getAvatarUrl()),
      ),
    ),

    const Spacer(),

    // Tombol Edit Profil jika akun sendiri
    if (isOwnProfile)
      OutlinedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfilePage(userData: userProfile),
            ),
          );
          fetchUserProfile();
          fetchUserPosts();
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: const Text('Edit Profil',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            )),
      )
        else
      ElevatedButton(
        onPressed: toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white : const Color(0xFF2E7D32),
          side: BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          isFollowing ? "Mengikuti" : "Ikuti",
          style: TextStyle(
            color: isFollowing ? const Color(0xFF2E7D32) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    const SizedBox(width: 8),  
  ],
),



                            // Name
                            Text(
                              userProfile?['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Username
                            Text(
                              '${userProfile?['username'] ?? ''}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 1),

                            // Bio
                            if (userProfile?['bio'] != null &&
                                userProfile!['bio'].toString().isNotEmpty)
                              Text(
                                userProfile!['bio'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 4),

                            // Location & Join Date
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                if (userProfile?['location'] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        userProfile!['location'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                               
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Following & Followers
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    // Navigate to following list
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${userPosts.length} ', 
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Postingan',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                InkWell(
                                  onTap: () {
                                    // Navigate to followers list
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${userProfile?['followers_count'] ?? 0} ',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Koneksi',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tabs
                     // Tabs
Container(
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(color: Colors.grey[300]!),
    ),
  ),
  child: TabBar(
    controller: _tabController,
    labelColor: Colors.black,
    unselectedLabelColor: Colors.grey[600],
    indicatorColor: Colors.green,
    indicatorWeight: 3,
    tabs: const [
      Tab(text: 'Postingan'),
    ],
  ),
),

                    ],
                  ),
                ),

                // Posts Content - Tab View
 // Posts Content
SliverPadding(
  padding: const EdgeInsets.all(2),
  sliver: isLoadingPosts
      ? SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          ),
        )
      : userPosts.isEmpty
          ? SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada postingan'),
                    ],
                  ),
                ),
              ),
            )
          : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 kolom
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1, // buat kotak
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = userPosts[index];
                  final imageUrl = getPostImageUrl(post);

                  return GestureDetector(
                    onTap: () => navigateToPostDetail(post),
                    child: Container(
                      color: Colors.grey[200],
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            )
                          : Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
                childCount: userPosts.length,
              ),
            ),
),

              ],
            ),
    );
  }
}