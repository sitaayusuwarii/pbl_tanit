import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_tanit/screens/detail_post.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({Key? key}) : super(key: key);

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  List<dynamic> savedPosts = [];
  bool isLoading = true;
  bool hasMore = false; // asumsi default false, akan diupdate dari API
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  // Sesuaikan base U

  @override
  void initState() {
    super.initState();
    fetchSavedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  String _normalizeImageUrl(dynamic urlOrPath) {
  if (urlOrPath == null) return '';
  final s = urlOrPath.toString();
  if (s.isEmpty) return '';
  if (s.startsWith('http')) return s;
  return '${AppConfig.storageUrl}$s';
}


  // Fetch saved posts dari API (mendukung 2 format response)
  Future<void> fetchSavedPosts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMore = false;
      });
    }

    try {
      final token = await _getToken();
      final uri = Uri.parse('${AppConfig.baseUrl}/saved-posts?page=$currentPage');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Jika API mengembalikan object dengan key 'posts'
        if (data is Map && data.containsKey('posts')) {
          final posts = data['posts'] as List<dynamic>? ?? [];
          setState(() {
            if (loadMore) {
              savedPosts.addAll(posts);
            } else {
              savedPosts = posts;
            }
            hasMore = data['has_more'] ?? false;
            isLoading = false;
          });
        } else if (data is List) {
          // Jika API mengembalikan list langsung (mis. list SavedPost models)
          setState(() {
            if (loadMore) {
              savedPosts.addAll(data);
            } else {
              savedPosts = data;
            }
            // Tidak ada info pagination -> matikan hasMore
            hasMore = false;
            isLoading = false;
          });
        } else {
          // fallback safe
          setState(() {
            savedPosts = [];
            hasMore = false;
            isLoading = false;
          });
        }
      } else {
        print('fetchSavedPosts failed: ${response.statusCode} ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e, st) {
      print('Error fetchSavedPosts: $e\n$st');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle scroll untuk load more
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        setState(() {
          currentPage++;
        });
        fetchSavedPosts(loadMore: true);
      }
    }
  }

  // Handle unsave post (gunakan POST sesuai controller yang disarankan)
  Future<void> handleUnsavePost(int postId, int index) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${AppConfig.baseUrl}/posts/$postId/unsave');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          // Hapus item lokal
          if (index >= 0 && index < savedPosts.length) {
            savedPosts.removeAt(index);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postingan dihapus dari tersimpan'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Unsave failed: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      print('Error unsave: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menghapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle like post
  Future<void> handleLike(int postId, int index) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${AppConfig.baseUrl}/posts/$postId/like');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // savedPosts berisi saved record, item['post'] berisi post
          if (index >= 0 && index < savedPosts.length) {
            final saved = savedPosts[index];
            final post = saved is Map ? saved['post'] ?? saved : saved;
            if (post is Map) {
              post['is_liked'] = !(post['is_liked'] == true);
              if (data is Map && data.containsKey('likes_count')) {
                post['likes_count'] = data['likes_count'];
              }
              // Jika saved is Map objektif, assign kembali (untuk safety)
              if (saved is Map) saved['post'] = post;
              savedPosts[index] = saved;
            }
          }
        });
      } else {
        print('Like failed: ${response.statusCode} ${response.body}');
      }
    } catch (e, st) {
      print('Error like: $e\n$st');
    }
  }

 void navigateToPostDetail(Map<String, dynamic> post) async {
  final fixedPost = Map<String, dynamic>.from(post);

  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getInt('user_id') ?? 0;

  // fallback user kalau null
  if (fixedPost['user'] == null) {
    fixedPost['user'] = {
      'id': fixedPost['user_id'],
      'name': fixedPost['user_name'] ?? '',
      'avatar_url': fixedPost['avatar_url'],
      'is_following': false,
    };
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailPostPage(
        post: fixedPost, // ✅ PENTING
        currentUserId: currentUserId,
        likedPostIds: savedPosts
            .map((s) {
              final p = s is Map && s.containsKey('post') ? s['post'] : s;
              return p is Map && p['is_liked'] == true ? p['id'] : null;
            })
            .whereType<int>()
            .toSet(),
        onLikeToggle: (postId) {
          final index = savedPosts.indexWhere((s) {
            final p = s is Map && s.containsKey('post') ? s['post'] : s;
            return p is Map && p['id'] == postId;
          });

          if (index != -1) {
            setState(() {
              final saved = savedPosts[index];
              final p = saved is Map && saved.containsKey('post')
                  ? saved['post']
                  : saved;

              p['is_liked'] = !(p['is_liked'] ?? false);
              p['likes_count'] =
                  (p['likes_count'] ?? 0) + (p['is_liked'] ? 1 : -1);
            });
          }
        },
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
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Postingan Tersimpan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading && savedPosts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : savedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada postingan tersimpan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simpan postingan favorit Anda di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
    color: Colors.green,
    onRefresh: () => fetchSavedPosts(),
    child: GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 kolom
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1, // kotak
      ),
      itemCount: savedPosts.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == savedPosts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        final saved = savedPosts[index];

       // Ambil post dari berbagai kemungkinan struktur
        final Map<String, dynamic> post = (() {
          if (saved is Map && saved.containsKey('post')) {
            return Map<String, dynamic>.from(saved['post']);
          } else if (saved is Map) {
            return Map<String, dynamic>.from(saved);
          }
          return <String, dynamic>{};
        })();


        final imageRaw = post['image'] ?? post['image_url'];
        final imageUrl = _normalizeImageUrl(imageRaw);

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
                : const Icon(Icons.image_not_supported,
                    color: Colors.grey),
          ),
        );
      },
    ),
  ),
    );
  }
}
