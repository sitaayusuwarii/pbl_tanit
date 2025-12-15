import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CariPage extends StatefulWidget {
  const CariPage({super.key});

  @override
  State<CariPage> createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  bool _loading = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': '📱', 'color': Color(0xFF2E7D32)},
    {'name': 'Padi', 'icon': '🌾', 'color': Color(0xFFFFA726)},
    {'name': 'Kopi', 'icon': '☕', 'color': Color(0xFF8D6E63)},
    {'name': 'Cokelat', 'icon': '🍫', 'color': Color(0xFF6D4C41)},
    {'name': 'Jagung', 'icon': '🌽', 'color': Color(0xFFFFEB3B)},
    {'name': 'Sayuran', 'icon': '🥬', 'color': Color(0xFF66BB6A)},
    {'name': 'Buah-buahan', 'icon': '🍎', 'color': Color(0xFFEF5350)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://10.11.3.86:8000/api/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _posts = data;
          _filteredPosts = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetch posts: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPosts = _posts.where((post) {
        final matchesCategory = _selectedCategory == 'Semua' ||
            post['category'] == _selectedCategory;
        final matchesSearch = query.isEmpty ||
            (post['description'] ?? '').toLowerCase().contains(query) ||
            (post['user'] ?? '').toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _filterPosts();
  }

  void _showPostDetail(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildUserHeader(post),
              const SizedBox(height: 16),
              Text(
                post['description'] ?? '',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (post['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildErrorImage(),
                  ),
                ),
              const SizedBox(height: 16),
              if (post['category'] != null) _buildCategoryChip(post['category']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic> post) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFF2E7D32),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['user'] ?? 'User',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            ),
            Text('Petani', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorImage() => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 48),
      );

  Widget _buildCategoryChip(String category) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.category_outlined, size: 14, color: Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(category,
              style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryList(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    )
                  : _filteredPosts.isEmpty
                      ? _buildEmptyState()
                      : _buildPostGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari postingan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterPosts();
                          },
                        )
                      : null,
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoryList() => SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['name'];
            return GestureDetector(
              onTap: () => _selectCategory(category['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category['icon'] as String),
                    const SizedBox(width: 6),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildPostGrid() => GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _filteredPosts.length,
        itemBuilder: (context, index) {
          final post = _filteredPosts[index];
          return GestureDetector(
            onTap: () => _showPostDetail(post),
            child: Container(
              color: Colors.grey[100],
              child: post['image_url'] != null
                  ? Image.network(
                      post['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildErrorImage(),
                    )
                  : const Icon(Icons.article, color: Color(0xFF2E7D32)),
            ),
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada hasil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Coba kata kunci lain', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
}
