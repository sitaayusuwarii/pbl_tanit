import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({Key? key}) : super(key: key);

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  List<dynamic> savedPosts = [];
  bool isLoading = true;
  bool hasMore = true;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

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

  // Fetch saved posts dari API
  Future<void> fetchSavedPosts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.20.2.176/api/saved-posts?page=$currentPage'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (loadMore) {
            savedPosts.addAll(data['posts'] ?? []);
          } else {
            savedPosts = data['posts'] ?? [];
          }
          hasMore = data['has_more'] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  

  // Handle scroll untuk load more
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        setState(() {
          currentPage++;
        });
        fetchSavedPosts(loadMore: true);
      }
    }
  }

  // Handle unsave post
  Future<void> handleUnsavePost(int postId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.20.2.176/api/posts/$postId/unsave'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          savedPosts.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postingan dihapus dari tersimpan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Handle like post
  Future<void> handleLike(int postId, int index) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.20.2.176/api/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          savedPosts[index]['is_liked'] = !savedPosts[index]['is_liked'];
          savedPosts[index]['likes_count'] = data['likes_count'];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Navigate to post detail
  void navigateToPostDetail(int postId) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PostDetailPage(postId: postId),
    //   ),
    // );
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
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: savedPosts.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      if (index == savedPosts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          ),
                        );
                      }

                      final post = savedPosts[index];
                      return InkWell(
                        onTap: () => navigateToPostDetail(post['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  post['user']['avatar'] ??
                                      'https://ui-avatars.com/api/?name=${post['user']['name']}&background=10b981&color=fff',
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User info and menu
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                post['user']['name'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '@${post['user']['username'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '·',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                post['created_at'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton(
                                          icon: Icon(
                                            Icons.more_horiz,
                                            color: Colors.grey[600],
                                          ),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              onTap: () {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () => handleUnsavePost(post['id'], index),
                                                );
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.bookmark_remove,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Hapus dari tersimpan'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Caption
                                    if (post['caption'] != null &&
                                        post['caption'].toString().isNotEmpty)
                                      Text(
                                        post['caption'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    const SizedBox(height: 8),

                                    // Image
                                    if (post['image'] != null || post['image_url'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          post['image'] ?? post['image_url'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 12),

                                    // Action buttons
                                    Row(
                                      children: [
                                        // Comment
                                        InkWell(
                                          onTap: () => navigateToPostDetail(post['id']),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.chat_bubble_outline,
                                                size: 18,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${post['comments_count'] ?? 0}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 48),

                                        // Like
                                        InkWell(
                                          onTap: () => handleLike(post['id'], index),
                                          child: Row(
                                            children: [
                                              Icon(
                                                post['is_liked'] == true
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 18,
                                                color: post['is_liked'] == true
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${post['likes_count'] ?? 0}',
                                                style: TextStyle(
                                                  color: post['is_liked'] == true
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 48),

                                        // Bookmark (already saved)
                                        Icon(
                                          Icons.bookmark,
                                          size: 18,
                                          color: Colors.green[700],
                                        ),
                                        const Spacer(),

                                        // Share
                                        Icon(
                                          Icons.share_outlined,
                                          size: 18,
                                          color: Colors.grey[600],
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
                    },
                  ),
                ),
    );
  }
}