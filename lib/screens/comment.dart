import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class CommentPage extends StatefulWidget {
  final int postId;
  final int initialCommentsCount;

  const CommentPage({
    Key? key,
    required this.postId,
    required this.initialCommentsCount,
  }) : super(key: key);

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  int? _replyToCommentId;
  String? _replyToUserName;
  int? _currentUserId;

  Set<int> _expandedReplies = {}; // commentId yg dibuka
  bool canDeleteComment(Map<String, dynamic> comment) {
  final commentUserId = comment['user']?['id'];
  final postOwnerId = comment['post']?['user_id']; // pastikan API memberikan ini
  return commentUserId == _currentUserId || postOwnerId == _currentUserId;
}


  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/posts/${widget.postId}/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data is List ? data : data['data']);
        });
      }
    } catch (e) {
      print('Error fetch comments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _postComment() async {
  final text = _commentController.text.trim();
  if (text.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final body = <String, dynamic>{
    'content': text,
  };

  // Kirim parent_id jika balasan
  if (_replyToCommentId != null) {
    body['parent_id'] = _replyToCommentId;
  }

  try {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/posts/${widget.postId}/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _commentController.clear();
      _cancelReply();
      await _fetchComments(); // Refresh komentar
      _scrollToBottom(); // scroll ke bawah biar lihat komentar baru
    }
  } catch (e) {
    print('Error posting comment: $e');
  }
}

Future<void> _deleteComment(int commentId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  try {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
        _expandedReplies.remove(commentId);
      });
    } else {
      print('Gagal menghapus komentar: ${response.body}');
    }
  } catch (e) {
    print('Error delete comment: $e');
  }
}


Future<void> _toggleLikeReply(int parentIndex, int replyIndex) async {
  final reply = _comments[parentIndex]['replies'][replyIndex];
  final replyId = reply['id'];
  final previousLiked = reply['is_liked'] ?? false;
  final previousCount = reply['likes_count'] ?? 0;

  // Optimistic update
  setState(() {
    _comments[parentIndex]['replies'][replyIndex]['is_liked'] = !previousLiked;
    _comments[parentIndex]['replies'][replyIndex]['likes_count'] =
        previousLiked ? previousCount - 1 : previousCount + 1;
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  try {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/comments/$replyId/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        _comments[parentIndex]['replies'][replyIndex]['is_liked'] =
            data['liked'] ?? _comments[parentIndex]['replies'][replyIndex]['is_liked'];
        _comments[parentIndex]['replies'][replyIndex]['likes_count'] =
            data['likes_count'] ?? _comments[parentIndex]['replies'][replyIndex]['likes_count'];
      });
    } else {
      // rollback jika gagal
      setState(() {
        _comments[parentIndex]['replies'][replyIndex]['is_liked'] = previousLiked;
        _comments[parentIndex]['replies'][replyIndex]['likes_count'] = previousCount;
      });
    }
  } catch (e) {
    print('Error like reply: $e');
    setState(() {
      _comments[parentIndex]['replies'][replyIndex]['is_liked'] = previousLiked;
      _comments[parentIndex]['replies'][replyIndex]['likes_count'] = previousCount;
    });
  }
}



  Future<void> _toggleLikeComment(int commentId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final previousLiked = _comments[index]['is_liked'] ?? false;
    final previousCount = _comments[index]['likes_count'] ?? 0;

    // Optimistic update
    setState(() {
      _comments[index]['is_liked'] = !previousLiked;
      _comments[index]['likes_count'] = previousLiked ? previousCount - 1 : previousCount + 1;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/comments/$commentId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _comments[index]['is_liked'] = data['is_liked'] ?? data['liked'];
          _comments[index]['likes_count'] = data['likes_count'] ?? _comments[index]['likes_count'];
        });
      } else {
        // Rollback
        setState(() {
          _comments[index]['is_liked'] = previousLiked;
          _comments[index]['likes_count'] = previousCount;
        });
      }
    } catch (e) {
      print('Error liking comment: $e');
      // Rollback
      setState(() {
        _comments[index]['is_liked'] = previousLiked;
        _comments[index]['likes_count'] = previousCount;
      });
    }
  }

  void _replyToComment(int commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Baru saja';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}j';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}h';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  String _getAvatarUrl(Map<String, dynamic>? user) {
    if (user == null) return '';
    final avatar = user['avatar_url'];
    if (avatar == null || avatar.toString().isEmpty) return '';
    
    final a = avatar.toString();
    if (a.startsWith('http')) return a;
    
    final clean = a.replaceFirst('storage/', '');
    return '${AppConfig.storageUrl}$clean';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context, _comments.length),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              '${_comments.length} komentar',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey[200]),
          
          // Reply indicator
          if (_replyToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Membalas $_replyToUserName',
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada komentar',
                              style: TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 16,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
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
  controller: _scrollController,
  padding: const EdgeInsets.symmetric(vertical: 8),
  itemCount: _comments.length,
  itemBuilder: (context, index) {
    final comment = _comments[index];
    final user = comment['user'] ?? {};
    final avatarUrl = _getAvatarUrl(user);
    final isLiked = comment['is_liked'] == true;
    final likesCount = comment['likes_count'] ?? 0;
    final isOwnComment = comment['user']?['id'] == _currentUserId;

    // cek bisa hapus komentar
    bool canDeleteComment(Map<String, dynamic> comment) {
      final commentUserId = comment['user']?['id'];
      final postOwnerId = comment['post']?['user_id']; // pastikan api ngirim post.user_id
      return (isOwnComment) || (_currentUserId == postOwnerId && commentUserId != _currentUserId);
    }

    Future<void> _deleteComment(int commentId) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      try {
        final response = await http.delete(
          Uri.parse('${AppConfig.baseUrl}/comments/$commentId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          setState(() {
            _comments.removeAt(index);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus komentar')),
          );
        }
      } catch (e) {
        print('Error deleting comment: $e');
      }
    }

    return GestureDetector(
      onLongPress: canDeleteComment(comment)
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus komentar?'),
                  content: const Text('Apakah kamu yakin ingin menghapus komentar ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteComment(comment['id']);
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Comment content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment bubble
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['name'] ?? 'User',
                                style: const TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            if (isOwnComment)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Anda',
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment['content'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 14,
                            color: Color(0xFF2C2C2C),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatTimestamp(comment['created_at']),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),

                        /// ❤️ LIKE
                        GestureDetector(
                          onTap: () => _toggleLikeComment(comment['id'], index),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: isLiked ? Colors.red : Colors.grey[600],
                              ),
                              if (likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text('$likesCount',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ],
                          ),
                        ),

                        /// 💬 BALAS
                        GestureDetector(
                          onTap: () =>
                              _replyToComment(comment['id'], user['name'] ?? 'User'),
                          child: const Text(
                            'Balas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        /// 👇 TAMPILKAN BALASAN
                        if ((comment['replies'] as List?)?.isNotEmpty == true)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_expandedReplies.contains(comment['id'])) {
                                  _expandedReplies.remove(comment['id']);
                                } else {
                                  _expandedReplies.add(comment['id']);
                                }
                              });
                            },
                            child: Text(
                              _expandedReplies.contains(comment['id'])
                                  ? 'Sembunyikan Balasan'
                                  : 'Tampilkan Balasan (${(comment['replies'] as List).length})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Replies (if any)
                  if (_expandedReplies.contains(comment['id']) && comment['replies'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 12),
                      child: Column(
                        children: (comment['replies'] as List)
                            .asMap()
                            .entries
                            .map((entry) => _buildReply(entry.value, entry.key, index))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyToCommentId != null
                              ? 'Tulis balasan...'
                              : 'Tulis komentar...',
                          hintStyle: TextStyle(
                            fontFamily: 'PublicSans',
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
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
                      onPressed: _postComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildReply(Map<String, dynamic> reply, int replyIndex, int parentIndex) {
  final user = reply['user'] ?? {};
  final avatarUrl = _getAvatarUrl(user);
  final isLiked = reply['is_liked'] == true;
  final likesCount = reply['likes_count'] ?? 0;
  final isOwnReply = reply['user']?['id'] == _currentUserId;

  bool canDeleteReply() {
    // Pemilik balasan atau pemilik postingan bisa hapus
    final postOwnerId = _comments[parentIndex]['post']?['user_id'];
    return isOwnReply || (_currentUserId == postOwnerId && reply['user']?['id'] != _currentUserId);
  }

  Future<void> _deleteReply() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/comments/${reply['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _comments[parentIndex]['replies'].removeAt(replyIndex);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus balasan')),
        );
      }
    } catch (e) {
      print('Error deleting reply: $e');
    }
  }

  return GestureDetector(
    onLongPress: canDeleteReply()
        ? () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus balasan?'),
                content: const Text('Apakah kamu yakin ingin menghapus balasan ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteReply();
                    },
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          }
        : null,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUBBLE BALASAN
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reply['content'] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ACTION BAR (LIKE · BALAS · WAKTU)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLikeReply(parentIndex, replyIndex),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            if (likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '$likesCount',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      GestureDetector(
                        onTap: () => _replyToComment(
                          reply['id'], // balasannya jadi parent
                          user['name'] ?? 'User',
                        ),
                        child: const Text(
                          'Balas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Text(
                        _formatTimestamp(reply['created_at']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
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