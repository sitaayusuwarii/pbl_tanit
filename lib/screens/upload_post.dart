import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config.dart';

class UploadPostScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const UploadPostScreen({super.key, required this.imageBytes});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final TextEditingController _descController = TextEditingController();
 
  
  bool _loading = false;

@override
void initState() {
  super.initState();
  _fetchCategories();
}

  List<dynamic> _categories = [];
String? _selectedCategoryId;

Future<void> _fetchCategories() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final res = await http.get(
    Uri.parse("${AppConfig.baseUrl}/categories"),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print("===== FETCH CATEGORIES DEBUG =====");
  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}");

  try {
    final decoded = jsonDecode(res.body);
    setState(() {
      _categories = decoded['data'] ?? [];
    });

  } catch (e) {
    print("JSON ERROR: $e");
  }
}





  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

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

if (_selectedCategoryId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Pilih kategori terlebih dahulu')),
  );
  setState(() => _loading = false);
  return;
}


  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final desc = _descController.text.trim();
    final category = _selectedCategoryId!;


    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/posts'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';


    request.headers['Authorization'] = 'Bearer $token';
    request.fields['description'] = desc;
    if (_selectedCategoryId != null) {
  request.fields['category_id'] = _selectedCategoryId!;
}



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
      // ✅ Tambahan: ambil URL dari respons server
      final decoded = jsonDecode(responseBody);
      final imageUrl = decoded['post']?['image_url'] ?? 
                 decoded['data']?['image_url'] ?? 
                 decoded['image_url'] ?? '';


      // ✅ Simpan ke SharedPreferences biar bisa di-load lagi nanti
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
  print("🔴 POSTING ERROR ${response.statusCode}");
  print("🔴 BODY: $responseBody");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Gagal posting: $responseBody'),
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
    setState(() => _loading = false);
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
                decoration: BoxDecoration(
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
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: Row(
            //     children: [
            //       Container(
            //         decoration: BoxDecoration(
            //           shape: BoxShape.circle,
            //           gradient: const LinearGradient(
            //             colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
            //             begin: Alignment.topLeft,
            //             end: Alignment.bottomRight,
            //           ),
            //           boxShadow: [
            //             BoxShadow(
            //               color: const Color(0xFF2E7D32).withOpacity(0.3),
            //               blurRadius: 8,
            //               offset: const Offset(0, 2),
            //             ),
            //           ],
            //         ),
            //         padding: const EdgeInsets.all(2),
            //         child: const CircleAvatar(
            //           backgroundColor: Colors.white,
            //           radius: 20,
            //           child: Icon(
            //             Icons.person,
            //             color: Color(0xFF2E7D32),
            //             size: 24,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       const Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'Anda',
            //             style: TextStyle(
            //               fontFamily: 'PublicSans',
            //               fontWeight: FontWeight.w700,
            //               fontSize: 16,
            //               color: Color(0xFF1A1A1A),
            //             ),
            //           ),
            //           SizedBox(height: 2),
            //           Text(
            //             'Petani',
            //             style: TextStyle(
            //               fontFamily: 'PublicSans',
            //               fontSize: 13,
            //               color: Colors.grey,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),

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
                      // Overlay gradient for zoom icon
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
                      // Zoom icon indicator
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
                              Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 18,
                              ),
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

            // Category Section
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
                  // Dropdown Category
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // ← tambah height
  height: 50, // ← WAJIB! Biar dropdown area kliknya ada
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[300]!),
  ),
  
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      isExpanded: true,   // ← WAJIB BIAR MELEBAR
      value: _selectedCategoryId,
      hint: const Text("Pilih kategori"),
      
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
      items: _categories.map<DropdownMenuItem<String>>((category) {
        return DropdownMenuItem<String>(
          value: category['id'].toString(),
          child: Text(category['category']),
        );
        
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
    ),
  ),
)




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
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF2E7D32),
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