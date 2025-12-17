import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:share_plus/share_plus.dart';

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

class DetailPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final int? currentUserId;
  final Set<int> likedPostIds;
  final Function(int) onLikeToggle;

  const DetailPostPage({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.likedPostIds,
    required this.onLikeToggle,
  }) : super(key: key);

  @override
  State<DetailPostPage> createState() => _DetailPostPageState();
}

class _DetailPostPageState extends State<DetailPostPage> {
  late Map<String, dynamic> _post;
  late bool _isLiked;
  late bool _isFollowing;
  bool _isSaved = false;


 @override
void initState() {
  super.initState();
  _post = Map<String, dynamic>.from(widget.post);
   _isLiked = _post['liked_by_user'] == true;
  _isFollowing = false;

  _forceInjectCurrentUser(); 
  _checkIsSaved();

}

Future<void> _checkIsSaved() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";

  final response = await http.get(
    Uri.parse("${AppConfig.baseUrl}/posts/${_post['id']}/is-saved"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      _isSaved = data['saved'] == true;
    });
  }
}

Future<void> _toggleSavePost() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";

  final response = await http.post(
    Uri.parse("${AppConfig.baseUrl}/posts/${_post['id']}/save"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      _isSaved = !_isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? "Postingan disimpan" : "Batal simpan postingan"),
        backgroundColor: Colors.green,
      ),
    );
  }
}

Future<void> _deletePost() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";

  final response = await http.delete(
    Uri.parse("${AppConfig.baseUrl}/posts/${_post['id']}"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );

  if (response.statusCode == 200) {
    Navigator.pop(context); // balik ke halaman sebelumnya
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Postingan berhasil dihapus"),
        backgroundColor: Colors.red,
      ),
    );
  }
}



Future<void> _forceInjectCurrentUser() async {
  final me = await _getLoggedInUser();
  if (me == null) return;

  final postUser = _post['user'];

  setState(() {
    // 🔥 JIKA USER NULL → PAKSA ISI DARI LOGIN
    if (postUser == null) {
      _post['user'] = {
        'id': me['id'],
        'name': me['name'],
        'avatar_url': me['avatar_url'],
        'is_following': false,
      };
      _isFollowing = false;
    }
    // 🔥 JIKA POST SENDIRI → TIMPA DENGAN DATA LOGIN
    else if (postUser['id'] == me['id']) {
      _post['user'] = {
        'id': me['id'],
        'name': me['name'],
        'avatar_url': me['avatar_url'],
        'is_following': false,
      };
      _isFollowing = false;
    }
    // 🔹 POST ORANG LAIN
    else {
      _isFollowing =
          _getUserData(postUser)['is_following'] ?? false;
    }
  });
}



String fixLaravelImagePath(String img) {
  if (img.startsWith("http")) return img;

  if (img.startsWith("/")) {
    img = img.substring(1);
  }

  if (!img.startsWith("storage/")) {
    img = "storage/$img";
  }

  return "${AppConfig.baseUrl.replaceAll('/api', '')}/$img";
}




Future<Map<String, dynamic>?> _getLoggedInUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userString = prefs.getString('user');
  if (userString == null) return null;
  return jsonDecode(userString);
}

  Map<String, dynamic> _getUserData(dynamic userData) {
    if (userData == null) return {'id': null, 'name': 'User', 'avatar_url': null, 'is_following': false};
    if (userData is Map) {
      int? userId = userData['id'] is int ? userData['id'] : int.tryParse(userData['id'].toString());
      return {
        'id': userId,
        'name': userData['name']?.toString() ?? 'User',
        'avatar_url': userData['avatar_url']?.toString(),
        'is_following': userData['is_following'] == true || userData['is_following'] == 1,
      };
    }
    return {'id': null, 'name': 'User', 'avatar_url': null, 'is_following': false};
  }

 String getAvatarUrl(Map<String, dynamic>? userData) {
  if (userData == null) return '';

  final avatar = userData['avatar_url'];
  if (avatar == null || avatar.toString().isEmpty) return '';

  return fixLaravelImagePath(avatar.toString());
}



String getPostImageUrl(Map<String, dynamic> post) {
  final img = post['image'] ?? post['image_url'];
  if (img == null || img.toString().isEmpty) return '';
  // pakai AppConfig.storageUrl
  return img.toString().startsWith('http') ? img : '${AppConfig.storageUrl}$img';
}

Future<void> _followUser() async {
  final userId = _getUserData(_post['user'])['id'];
  if (userId == null || userId == widget.currentUserId) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/users/$userId/follow'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      _isFollowing = data['is_following'] == true;
    });
  }
}



//  String getPostImageUrl(Map<String, dynamic> post) {
//   final img = post['image'] ?? post['image_url'];
//   if (img == null || img.toString().isEmpty) return '';
//   // pakai AppConfig.storageUrl
//   return img.toString().startsWith('http') ? img : '${AppConfig.storageUrl}$img';
// }

Future<void> _toggleLike() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  // 🔥 optimistic UI
  setState(() {
    _isLiked = !_isLiked;
    _post['likes_count'] =
        (_post['likes_count'] ?? 0) + (_isLiked ? 1 : -1);
    _post['liked_by_user'] = _isLiked;
  });

  try {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/posts/${_post['id']}/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _isLiked = data['liked_by_user'] == true;
        _post['likes_count'] = data['likes_count'];
        _post['liked_by_user'] = _isLiked;
      });
    }
  } catch (e) {
    // rollback
    setState(() {
      _isLiked = !_isLiked;
      _post['likes_count'] =
          (_post['likes_count'] ?? 0) + (_isLiked ? 1 : -1);
      _post['liked_by_user'] = _isLiked;
    });
  }
}



void _showComments(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final TextEditingController commentController = TextEditingController();

    List initialComments = [];
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        initialComments = jsonDecode(res.body);
      }
    } catch (e) {
      print('Error fetch komentar: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List comments = initialComments;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            final ScrollController scrollController = ScrollController();

            void _scrollToBottom() {
              if (scrollController.hasClients) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  scrollController.animateTo(
                    scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                });
              }
            }

            if (comments.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komentar',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${comments.length}',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 10),

                  // Daftar komentar
                  Expanded(
                    child: comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada komentar',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jadilah yang pertama berkomentar!',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: comments.length,
                            itemBuilder: (context, i) {
                              final c = comments[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                  radius: 20,
                                  backgroundImage: getAvatarUrl(c['user']).isNotEmpty
                                      ? NetworkImage(getAvatarUrl(c['user']))
                                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                                ),

                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c['user']?['name'] ?? 'User',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontFamily: 'PublicSans',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  c['content'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14,
                                                    fontFamily: 'PublicSans',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12),
                                            child: Text(
                                              c['created_at'] != null
                                                  ? _formatTimestamp(c['created_at'])
                                                  : 'Baru saja',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                                fontFamily: 'PublicSans',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 8),

                  // Input komentar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              hintStyle: TextStyle(
                                fontFamily: 'PublicSans',
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: () async {
                              final text = commentController.text.trim();
                              if (text.isEmpty) return;

                              try {
                                final response = await http.post(
  Uri.parse('${AppConfig.baseUrl}/posts/$postId/comments'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: jsonEncode({'content': text}),
);

print("STATUS CODE: ${response.statusCode}");
print("BODY: ${response.body}");


                                if (response.statusCode == 200 || response.statusCode == 201) {
                                final newComment = jsonDecode(response.body);

                                setStateModal(() {
                                  comments.add(newComment); // append komentar baru
                                  commentController.clear();
                                });

                                setState(() {
                                  _post['comments_count'] =
                                      (_post['comments_count'] ?? 0) + 1;
                                });


                                FocusScope.of(context).unfocus();
                                _scrollToBottom();
                              } else {
                                print('Gagal kirim komentar: ${response.statusCode} - ${response.body}');
                              }

                              } catch (e) {
                                print('Error kirim komentar: $e');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
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
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  void _sharePost(Map<String, dynamic> post) async {
    final userData = _getUserData(post['user']);
    final postId = post['id'];
    
    // Buat link yang bisa dibuka (sesuaikan dengan domain aplikasi Anda)
    final link = 'https://tanitalk.app/posts/$postId'; // Ganti dengan domain Anda
    
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
 

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = _getUserData(_post['user']);
    final avatarUrl = getAvatarUrl(userData);
    final isOwnPost = userData['id'] == widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  title: const Text(
    'Post',
    style: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
  actions: [
   PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert, color: Colors.black),
  onSelected: (value) {
    if (value == 'save') {
      _toggleSavePost();
    } else if (value == 'delete') {
      _deletePost();
    }
  },
  itemBuilder: (context) {
    final List<PopupMenuEntry<String>> items = [];

    // SIMPAN / BATAL SIMPAN
    items.add(
      PopupMenuItem<String>(
        value: 'save',
        child: Row(
          children: [
            Icon(
              Icons.bookmark_border,
              size: 20,
              color: Colors.green[700],
            ),
            const SizedBox(width: 12),
            Text(
              _isSaved ? 'Batal Simpan' : 'Simpan',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    // HAPUS (hanya post sendiri)
    if (userData['id'] == widget.currentUserId) {
      items.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              SizedBox(width: 12),
              Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  },
),

  ],
),

      body: ListView(
        
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
  children: [

CircleAvatar(
  radius: 24,
  backgroundImage:
      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
  child: avatarUrl.isEmpty
      ? const Icon(Icons.person, color: Color(0xFF2E7D32))
      : null,
),

    const SizedBox(width: 12),
    Expanded(
      child: Text(
        userData['name'],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

     ],
),

          const SizedBox(height: 12),

          // Description
          Text(_post['description'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 12),

          // Image
          if (_post['image'] != null || _post['image_url'] != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: getPostImageUrl(_post))),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(getPostImageUrl(_post), fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 12),

          // Category
          if (_post['category'] != null)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.category_outlined, size: 14, color: Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        Text(
          _post['category']['category'],
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    ),
  ),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${_post['likes_count'] ?? 0}',
                  color: _isLiked ? Colors.red : Colors.grey[700]!,
                  onTap: _toggleLike),
              _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${_post['comments_count'] ?? 0}',
                        color: Colors.grey[700]!,
                        onTap: () => _showComments(_post['id']),
                      ),
              _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Bagikan',
                  color: Colors.grey[700]!,
                  onTap: () => _sharePost(_post),),
            ],
          ),
        ],
      ),
    );
  }
}
