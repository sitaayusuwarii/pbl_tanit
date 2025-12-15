import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Wajib ada untuk simpan role

// Import Halaman Admin
import 'package:pbl_tanit/screens/admin/categories/category_list_page.dart';
import 'package:pbl_tanit/screens/admin/dashboard/admin_dashboard.dart';
import 'package:pbl_tanit/screens/admin/users/user_list_page.dart';
import 'package:pbl_tanit/screens/admin/posts/post_list_page.dart';
import 'package:pbl_tanit/screens/admin/categories/category_add_page.dart';
import 'package:pbl_tanit/screens/admin/categories/category_edit_page.dart';
import 'package:pbl_tanit/screens/admin/users/user_detail_page.dart';

// Import Halaman User/Auth
import 'package:pbl_tanit/screens/home.dart';
import 'package:pbl_tanit/screens/register.dart';
import 'package:pbl_tanit/screens/login.dart';
import 'package:pbl_tanit/screens/landing_page.dart';
import 'package:pbl_tanit/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tani Talk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green[800]!,
          secondary: Colors.green[400]!,
        ),
        scaffoldBackgroundColor: Colors.green[50],
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      
      // --- PERUBAHAN DISINI ---
      // Kita tidak pakai initialRoute string lagi, tapi pakai logic CheckAuth
      home: const CheckAuth(), 
      // ------------------------

      routes: {
        '/splash_screen': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/admin/categories': (context) => const CategoryListPage(),
        '/admin/posts': (context) => const PostListPage(),
        '/admin/users': (context) => const UserListPage(),
        '/admin/users/detail': (context) => const UserDetailPage(),
        '/home': (context) => const HomeScreen(),
        '/admin/categories/add': (context) => const CategoryAddPage(),
        '/admin/categories/edit': (context) => const CategoryEditPage(),
      },
    );
  }
}

// --- WIDGET LOGIKA PENGECEKAN LOGIN (ADMIN vs USER) ---
class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});

  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  bool _isChecking = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Simulasi delay splash screen (opsional, biar logo tampil sebentar)
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role'); // Pastikan di Login Page sudah save role ini

    setState(() {
      if (token == null) {
        // Jika belum login, arahkan ke Landing Page atau Login
        _targetScreen = const LandingPage(); 
      } else {
        // Jika sudah login, cek Rolenya
        if (role == 'admin') {
          _targetScreen = const AdminDashboard();
        } else {
          _targetScreen = const HomeScreen();
        }
      }
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Selama masih loading (_isChecking), tampilkan SplashScreen
    if (_isChecking) {
      return const SplashScreen();
    }
    
    // Setelah selesai cek, tampilkan halaman tujuan (Admin/User/Landing)
    return _targetScreen!;
  }
}