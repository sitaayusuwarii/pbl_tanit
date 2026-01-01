import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/category_service.dart'; 

class UploadPostScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const UploadPostScreen({super.key, required this.imageBytes});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final TextEditingController _descController = TextEditingController();
  final CategoryService _categoryService = CategoryService(); 

  String? _selectedCategory;
  bool _loading = false; 
  
  // State untuk Data Kategori dari API
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true; 

  @override
  void initState() {
    super.initState();
    _fetchCategories(); 
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // FUNGSI 1: AMBIL KATEGORI DARI API 
  Future<void> _fetchCategories() async {
    try {
      final data = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        print("Error fetching categories: $e");
      }
    }
  }

  // FUNGSI 2: HELPER UNTUK STYLE (ICON & WARNA)
  Map<String, dynamic> _getCategoryStyle(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('padi')) return {'icon': '🌾', 'color': const Color(0xFFFFA726)};
    if (name.contains('kopi')) return {'icon': '☕', 'color': const Color(0xFF8D6E63)};
    if (name.contains('cokelat') || name.contains('kakao')) return {'icon': '🍫', 'color': const Color(0xFF6D4C41)};
    if (name.contains('jagung')) return {'icon': '🌽', 'color': const Color(0xFFFFEB3B)};
    if (name.contains('sayur')) return {'icon': '🥬', 'color': const Color(0xFF66BB6A)};
    if (name.contains('buah')) return {'icon': '🍎', 'color': const Color(0xFFEF5350)};
    if (name.contains('hidroponik')) return {'icon': '💧', 'color': Colors.blue};
    if (name.contains('bawang')) return {'icon': '🧄', 'color': const Color(0xFF795548)};
    if (name.contains('ternak') || name.contains('sapi')) return {'icon': '🐄', 'color': Colors.brown};
    
    // Default style untuk kategori lain yang belum terdaftar
    return {'icon': '🌱', 'color': const Color(0xFF2E7D32)}; 
  }

  // FUNGSI 3: KIRIM POSTINGAN 
  Future<void> _postImage() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Deskripsi tidak boleh kosong'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final desc = _descController.text.trim();
      final category = _selectedCategory ?? 'Uncategorized'; // Default jika user tidak pilih

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/posts'), 
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['description'] = desc;
      request.fields['category'] = category;

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          widget.imageBytes,
          filename: 'post_image.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📦 Server response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        
        // Coba berbagai kemungkinan key response gambar dari server
        final imageUrl = decoded['post']?['image_url'] ?? 
                         decoded['data']?['image_url'] ?? 
                         decoded['image_url'] ?? '';

        await prefs.setString('lastUploadedImageUrl', imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Postingan berhasil dipublikasikan!'),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal posting: ${response.statusCode}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFullImage() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Postingan',
          style: TextStyle(
            fontFamily: 'PublicSans',
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _loading ? null : _postImage,
              style: TextButton.styleFrom(
                backgroundColor: _loading 
                    ? Colors.grey[300] 
                    : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Posting',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
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
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF2E7D32),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anda',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Petani',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Description TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _descController,
                maxLines: null,
                minLines: 3,
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Bagikan pengalaman pertanian Anda...',
                  hintStyle: TextStyle(
                    fontFamily: 'PublicSans',
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Preview
            GestureDetector(
              onTap: _showFullImage,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1 / 1,
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Tap untuk perbesar',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- CATEGORY SECTION (DINAMIS) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Logika Loading / Empty / List Data
                  if (_isLoadingCategories)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Text(
                        "Tidak ada kategori tersedia.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _categories.map((catData) {
                        // Ambil nama kategori
                        final String categoryName = catData['category'] ?? 'Lainnya';
                        
                        // Tentukan style berdasarkan nama
                        final style = _getCategoryStyle(categoryName);
                        
                        final isSelected = _selectedCategory == categoryName;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = isSelected ? null : categoryName;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? style['color']
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? style['color']
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (style['color'] as Color).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  style['icon'],
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan postingan Anda sesuai dengan komunitas TaniTalk',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}