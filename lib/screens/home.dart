import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbl_tanit/screens/notifikasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../layout/main_layout.dart';
import 'cari.dart';
import 'chatbot.dart';
import 'komunitas.dart';
import 'profile.dart';
import 'upload_post.dart';
import 'user_profile.dart';
import 'comment.dart';
import '../config.dart';
import 'dart:ui';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF2E7D32),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _posts = [];
  bool _loadingPosts = true;
  String _currentFilter = 'untuk_anda';
  int? _currentUserId;
  
  // Tab controller for swipeable tabs
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = _tabController.index == 0 ? 'untuk_anda' : 'koneksi';
        });
        _fetchPosts();
      }
    });
    _loadCurrentUser();
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  Map<String, dynamic> _getUserData(dynamic userData) {
    if (userData == null) {
      return {'id': null, 'name': 'User', 'avatar_url': null, 'is_following': false};
    }

    if (userData is Map) {
      int? userId;
      if (userData['id'] is int) {
        userId = userData['id'];
      } else if (userData['id'] is String) {
        userId = int.tryParse(userData['id']);
      }

      return {
        'id': userId,
        'name': userData['name']?.toString() ?? 'User',
        'avatar_url': userData['avatar_url']?.toString(),
        'is_following': userData['is_following'] == true || userData['is_following'] == 1,
      };
    }

    if (userData is String) {
      return {'id': null, 'name': userData, 'avatar_url': null, 'is_following': false};
    }

    return {'id': null, 'name': 'User', 'avatar_url': null, 'is_following': false};
  }

  String fixLaravelImagePath(String img) {
    img = img.replaceAll("storage/", "");
    if (img.startsWith("/")) {
      img = img.substring(1);
    }
    return "${AppConfig.storageUrl}$img";
  }

  String getPostImageUrl(Map<String, dynamic> post) {
    final img = post['image'] ?? post['image_url'];
    if (img == null || img.toString().isEmpty) return '';
    final imgStr = img.toString();
    if (imgStr.startsWith("http")) return imgStr;
    return fixLaravelImagePath(imgStr);
  }

  String getAvatarFromPost(Map user) {
    final avatar = user["avatar_url"];
    if (avatar == null || avatar.toString().isEmpty) return '';
    final a = avatar.toString();
    if (a.startsWith("http")) return a;
    String clean = a.replaceFirst("storage/", "");
    return "${AppConfig.storageUrl}$clean";
  }

  String getAvatarFromHome(Map<String, dynamic>? user) {
    if (user == null) return '';
    final avatar = user['avatar_url'];
    if (avatar == null || avatar.toString().isEmpty) return '';
    final a = avatar.toString();
    if (a.startsWith('http')) return a;
    final cleanPath = a.replaceFirst("storage/", "");
    return "${AppConfig.storageUrl}$cleanPath";
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> toggleSavePost(int postId, int index) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";

  final bool isSaved = _posts[index]['is_saved'] == true;

  final response = await http.post(
    Uri.parse("${AppConfig.baseUrl}/posts/$postId/save"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    setState(() {
      _posts[index]['is_saved'] = !isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved
            ? "Postingan batal disimpan"
            : "Postingan disimpan"),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}


  Future<void> _fetchPosts() async {
    setState(() => _loadingPosts = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint = _currentFilter == 'koneksi'
          ? '${AppConfig.baseUrl}/posts/following'
          : '${AppConfig.baseUrl}/posts';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Map<String, dynamic>> posts = [];
        if (data is List) {
          posts = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          posts = List<Map<String, dynamic>>.from(data['data']);
        }

        posts = posts.map((p) {
          p['user'] ??= {};
          p['image_url'] ??= p['image'];
          p['likes_count'] ??= 0;
          p['is_saved'] = p['is_saved'] == true || p['is_saved'] == 1;

          final backendLiked = p['liked_by_user'] ?? p['is_liked'] ?? false;
          p['is_liked'] = backendLiked == true || backendLiked == 1;

          if (p['category'] != null && p['category'] is Map) {
            p['category_name'] = p['category']['category'];
          } else {
            p['category_name'] = 'Umum';
          }

          return p;
        }).toList();

        setState(() {
          _posts = posts;
        });
      } else {
        setState(() => _posts = []);
      }
    } catch (e) {
      debugPrint('Fetch posts error: $e');
      setState(() => _posts = []);
    } finally {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _followUser(int userId, int postIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/$userId/follow'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        setState(() {
          if (_posts[postIndex]['user'] != null && _posts[postIndex]['user'] is Map) {
            _posts[postIndex]['user']['is_following'] = data['is_following'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                data['is_following'] == true
                    ? 'Berhasil mengikuti'
                    : 'Berhenti mengikuti'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  String _formatPostTimestamp(String? timestamp) {
    if (timestamp == null) return 'Baru saja';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} minggu yang lalu';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  Widget _berandaPage() {
    if (_loadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _currentFilter == 'koneksi'
                  ? 'Belum ada postingan dari koneksi'
                  : 'Belum ada postingan',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentFilter == 'koneksi'
                  ? 'Ikuti pengguna untuk melihat postingan mereka'
                  : 'Mulai berbagi cerita pertanian Anda!',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final post = _posts[i];
          final bool isLiked = post['is_liked'] == true;

          final userData = _getUserData(post['user']);
          final int? userId = userData['id'];
          final String userName = userData['name'];
          final avatarUrl = getAvatarFromPost(post["user"]);
          final bool isFollowing = userData['is_following'];

          final bool isOwnPost = userId != null && userId == _currentUserId;

          return Container(
            key: ValueKey(post['id']),
            margin: const EdgeInsets.only(bottom: 1),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final currentUserId = prefs.getInt('user_id');

                          if (userId == currentUserId) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(userId: userId),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name, role, and timestamp
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final currentUserId = prefs.getInt('user_id');

                            if (userId == currentUserId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(userId: userId),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatPostTimestamp(post['created_at']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'PublicSans',
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ],
                          ),
                        ),
                      ),

                      // Follow Button
                      if (_currentFilter != 'koneksi' &&
                          userId != null &&
                          (_currentUserId == null || userId != _currentUserId)) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _followUser(userId, i),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isFollowing
                                    ? Colors.grey[200]
                                    : const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFollowing ? 'Mengikuti' : 'Ikuti',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isFollowing ? Colors.grey[700] : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // More options
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'save') {
                            toggleSavePost(post['id'], i);
                          } else if (value == 'delete') {
                            _deletePost(post['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                  color: const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  post['category_name'] ?? 'Umum',
                                  style: const TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),

                          PopupMenuItem(
  value: 'save',
  child: Row(
    children: [
      Icon(
        post['is_saved'] == true
            ? Icons.bookmark
            : Icons.bookmark_border,
        size: 20,
        color: post['is_saved'] == true
            ? Colors.red[700]
            : Colors.green[700],
      ),
      const SizedBox(width: 12),
      Text(
        post['is_saved'] == true
            ? 'Batal Simpan'
            : 'Simpan',
        style: TextStyle(
          color: post['is_saved'] == true
              ? Colors.red[700]
              : Colors.green[700],
        ),
      ),
    ],
  ),
),

                          if (isOwnPost)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red[700]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    post['description'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),

                  // Image
                  if (post["image"] != null || post["image_url"] != null) ...[
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12), // ✅ jarak IG
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12), // IG vibes
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(
                                imageUrl: post['image_url'].toString(),
                              ),
                            ),
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Image.network(
                            post['image_url'].toString(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],                 
                  // const SizedBox(height: 2),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: '${post['likes_count'] ?? 0}',
                        color: isLiked ? Colors.red : Colors.grey[700]!,
                        onTap: () => _toggleLike(post['id']),
                      ),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${post['comments_count'] ?? 0}',
                        color: Colors.grey[700]!,
                        onTap: () => _showComments(post['id'], post['comments_count'] ?? 0),
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        label: 'Bagikan',
                        color: Colors.grey[700]!,
                        onTap: () => _sharePost(post),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    final previousIsLiked = _posts[index]['is_liked'] == true;
    final previousLikesCount = _posts[index]['likes_count'] ?? 0;

    setState(() {
      _posts[index]['is_liked'] = !previousIsLiked;
      _posts[index]['likes_count'] =
          previousIsLiked ? previousLikesCount - 1 : previousLikesCount + 1;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        setState(() {
          final backendLiked =
              data['liked_by_user'] ?? data['is_liked'] ?? data['liked'];
          _posts[index]['is_liked'] = backendLiked == true || backendLiked == 1;
          _posts[index]['likes_count'] =
              data['likes_count'] ?? _posts[index]['likes_count'];
        });
      } else {
        setState(() {
          _posts[index]['is_liked'] = previousIsLiked;
          _posts[index]['likes_count'] = previousLikesCount;
        });
      }
    } catch (e) {
      setState(() {
        _posts[index]['is_liked'] = previousIsLiked;
        _posts[index]['likes_count'] = previousLikesCount;
      });
    }
  }

  void _showComments(int postId, int initialCount) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentPage(
          postId: postId,
          initialCommentsCount: initialCount,
        ),
      ),
    );

    // Update comment count if returned
    if (result != null && result is int) {
      setState(() {
        final index = _posts.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          _posts[index]['comments_count'] = result;
        }
      });
    }
  }

  void _sharePost(Map<String, dynamic> post) async {
    final userData = _getUserData(post['user']);
    final postId = post['id'];

    // Buat URL yang proper
    final link = 'https://tanitalk.app/posts/$postId';

    final text = '''
🌾 TaniTalk Post

${userData['name']} membagikan:
${post['description'] ?? ''}

Lihat selengkapnya: $link

#TaniTalk #Pertanian
    '''.trim();

    try {
      await Share.share(
        text,
        subject: 'Bagikan Postingan dari TaniTalk',
      );
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membagikan postingan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Buat Postingan',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildPostOption(
                icon: Icons.image_outlined,
                title: 'Unggah Foto',
                subtitle: 'Bagikan gambar dari galeri',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 12),
              _buildPostOption(
                icon: Icons.edit_outlined,
                title: 'Tulis Postingan',
                subtitle: 'Bagikan pemikiran Anda',
                onTap: () {
                  Navigator.pop(context);
                  _showTextPostSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadPostScreen(imageBytes: bytes),
      ),
    );

    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 800));
      _fetchPosts();
    }
  }

  void _showTextPostSheet() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                maxLines: 6,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Apa yang ingin Anda bagikan?',
                  hintStyle: TextStyle(
                    fontFamily: 'PublicSans',
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
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
                    final text = textController.text.trim();
                    if (text.isEmpty) return;

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';

                    final response = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/posts'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({'description': text}),
                    );

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      textController.clear();
                      Navigator.of(context).pop();
                      _fetchPosts();
                    }
                  },
                  child: const Text(
                    'Kirim',
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
        );
      },
    );
  }

  Future<void> _deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/posts/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _fetchPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postingan berhasil dihapus'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
  return [

    /// 🔹 APPBAR 1 — BERANDA + LONCENG
    SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      toolbarHeight: 60,
      title: const Text(
        'Beranda',
        style: TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotifikasiPage(),
              ),
            );
          },
        ),
      ],
    ),

    /// 🔹 APPBAR 2 — TABBAR (STICKY & NAIK)
    SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Untuk Anda'),
            Tab(text: 'Koneksi'),
          ],
        ),
      ),
    ),
  ];
},

        body: TabBarView(
          controller: _tabController,
          children: [
            _berandaPage(),
            _berandaPage(),
          ],
        ),
      ),
      const CariPage(),
      const ChatbotPage(),
      const KomunitasPage(),
      const ProfilePage(),
    ];

    return MainLayout(
      child: _pages[_selectedIndex],
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      onAddPressed: _showPostOptions,
    );
  }
}