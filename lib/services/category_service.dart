import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CategoryService {
  final String baseUrl = '${ApiConfig.baseUrl}/categories'; 

  // GET: Ambil semua kategori
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      // PRINT LOG UNTUK DEBUGGING
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Tampilkan error spesifik dari server
        throw Exception('Gagal: ${response.statusCode}'); 
      }
    } catch (e) {
      print('Error Koneksi: $e');
      rethrow;
    }
  }

  // POST: Tambah kategori baru
  Future<bool> addCategory(String categoryName) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'category': categoryName,
      }),
    );

    return response.statusCode == 201;
  }

  // DELETE: Hapus kategori
  Future<bool> deleteCategory(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }
}