import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DashboardService {
  
  // 1. Ambil Statistik (Panggil API baru yang kita buat di Langkah 1)
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/stats'), 
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Jika gagal, kembalikan nilai 0 agar aplikasi tidak crash
      return {
        'totalUsers': 0, 
        'totalPosts': 0, 
        'totalCategories': 0, 
        'totalComments': 0
      };
    }
  }

  // 2. Ambil Postingan Terbaru (Pakai API Post yang SUDAH ADA)
  // Kita tidak perlu buat API baru, cukup pakai yang ada tapi ambil 5 saja di UI
  // Atau lebih baik jika di Laravel PostController index mendukung ?limit=5
  Future<List<dynamic>> getRecentPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Kita panggil API posts biasa
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts'), 
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> allPosts = json.decode(response.body);
      
      // Ambil 5 data pertama saja (Client side filtering)
      // *Catatan: Idealnya filtering dilakukan di backend (?limit=5), 
      // tapi cara ini oke untuk data yang belum ribuan.
      return allPosts.take(5).toList(); 
    } else {
      return [];
    }
  }
}