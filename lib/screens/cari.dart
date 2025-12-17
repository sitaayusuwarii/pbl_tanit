import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_tanit/screens/profile.dart';
import 'detail_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class CariPage extends StatefulWidget {
  const CariPage({super.key});

  @override
  State<CariPage> createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  int _selectedMenu = 0; // 0: Cari Postingan, 1: Cari Teman
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  int? _currentUserId;
  bool _isSearching = false;
  bool _loading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<dynamic> _categories = []; 

 @override
void initState() {
  super.initState();
  _initSearch();
  _loadCurrentUser();
}

Future<void> _initSearch() async {
  await _fetchCategories();
  _searchPostsByCategory(0); // otomatis tampilkan postingan Semua
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  



Future<void> _loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _currentUserId = prefs.getInt('user_id');
  });
}


// @override
// void initState() {
//   super.initState();
//   _fetchCategories();
// }

Future<void> _searchCategoryByText(String query) async {
  query = query.toLowerCase().trim();

  // cari kategori di list local
  final matched = _categories.firstWhere(
    (cat) => cat['category'].toString().toLowerCase().contains(query),
    orElse: () => null,
  );

  if (matched != null) {
    // kategori ditemukan → ambil id
    final catId = matched['id'];

    setState(() {
      _selectedCategory = catId;
    });

    // langsung load postingan kategori itu
    _searchPostsByCategory(catId);
  } else {
    // kategori tidak ditemukan → kosongkan hasil
    setState(() {
      _searchResults = [];
    });
  }
}



Future<void> _fetchCategories() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/categories'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _categories = data['data'];   // <-- karena data['data'] berisi list kategori

        // Tambah kategori default
        _categories.insert(0, {
          "id": 0,
          "category": "Semua",
        });
      });
    }
  } catch (e) {
    print("Error fetch categories: $e");
  }
}



  // Search Posts by Category
Future<void> _searchPostsByCategory(int category) async {
  setState(() {
    _loading = true;
    _selectedCategory = category;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final baseUrl = "${AppConfig.baseUrl}/posts";

    final url = category == 0
        ? "$baseUrl?limit=100&random=true"
        : "$baseUrl?category_id=$category";

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("URL: $url");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['data']);
      });
    }
  } catch (e) {
    print("Error search posts: $e");
  } finally {
    setState(() => _loading = false);
  }
}





  // Search Posts by Keyword
  Future<void> _searchPosts(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
       Uri.parse('${AppConfig.baseUrl}/posts/search?q=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print('Error search posts: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Search Friends/Users
  Future<void> _searchFriends(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/search?q=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
         _searchResults = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print('Error search friends: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchSubmitted(String value) {
    if (_selectedMenu == 0) {
      _searchCategoryByText(value); 
    } else {
      _searchFriends(value);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      if (_selectedMenu == 0) {
        _selectedCategory = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pencarian',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Menu Tabs
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuTab(
                          title: 'Cari Postingan',
                          icon: Icons.article_outlined,
                          index: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuTab(
                          title: 'Cari Teman',
                          icon: Icons.people_outline,
                          index: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          if (_selectedMenu == 0) {
                            // Cari postingan berdasarkan kategori teks
                            _searchCategoryByText(value);
                          } else {
                            // Cari teman
                            _searchFriends(value);
                          }
                        },

                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _selectedMenu == 0
                              ? 'Cari postingan...'
                              : 'Cari nama teman...',
                          hintStyle: TextStyle(
                            fontFamily: 'PublicSans',
                            color: Colors.grey[500],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching && _selectedMenu == 1) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _clearSearch,
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Categories (Only for Cari Postingan)
            if (_selectedMenu == 0) ...[
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: _categories.length,
  itemBuilder: (context, index) {
    final cat = _categories[index];

    return GestureDetector(
      onTap: () {
        _searchPostsByCategory(cat['id']);
      },

      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedCategory == cat['id']
              ? Colors.green
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          cat['category'],
          style: TextStyle(
            color: _selectedCategory == cat['id']
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  },
),
              ),
            ],

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? _buildEmptyState()
                      : _selectedMenu == 0
                          ? _buildPostsGrid()
                          : _buildFriendsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedMenu == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMenu = index;
          _searchResults = [];
          _searchController.clear();
          _isSearching = false;
          if (index == 0) {
            _selectedCategory = 0;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedMenu == 0 ? Icons.search_off : Icons.person_search,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedMenu == 0
                ? 'Cari postingan atau pilih kategori'
                : 'Cari teman dengan nama',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMenu == 0
                ? 'Gunakan kategori atau search bar'
                : 'Ketik nama untuk mencari',
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

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return GestureDetector(
           onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPostPage(
                post: post,
                currentUserId: _currentUserId,
                likedPostIds: {}, // bisa diisi set post yang sudah di-like
                onLikeToggle: (postId) {
                  // contoh toggle like sederhana
                  setState(() {
                    final idx = _searchResults.indexWhere((p) => p['id'] == postId);
                    if (idx != -1) {
                      final isLiked = _searchResults[idx]['likes_count'] ?? 0;
                      _searchResults[idx]['likes_count'] = isLiked + 1;
                    }
                  });
                },
              ),
            ),
          );
        },
          child: Container(
            color: Colors.grey[100],
            child: post['image_url'] != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        post['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if ((post['likes_count'] ?? 0) > 0 ||
                          (post['comments_count'] ?? 0) > 0)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      if ((post['likes_count'] ?? 0) > 0 ||
                          (post['comments_count'] ?? 0) > 0)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((post['likes_count'] ?? 0) > 0)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post['likes_count']}',
                                      style: const TextStyle(
                                        fontFamily: 'PublicSans',
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              if ((post['comments_count'] ?? 0) > 0) ...[
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post['comments_count']}',
                                      style: const TextStyle(
                                        fontFamily: 'PublicSans',
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.article,
                          color: Color(0xFF2E7D32),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post['user']?['name'] ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PublicSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: user['avatar_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            user['avatar_url'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 28,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 28,
                          color: Color(0xFF2E7D32),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'User',
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user['bio'] != null && user['bio'].toString().isNotEmpty)
                      Text(
                        user['bio'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
             OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: user['id']),
                  ),
                );
              },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Lihat',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 void _showPostDetail(Map<String, dynamic> post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      post['user']?['name'] ?? 'User', // <-- ambil name dari user object
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (post['description'] != null)
                    Text(
                      post['description'],
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  if (post['image_url'] != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}