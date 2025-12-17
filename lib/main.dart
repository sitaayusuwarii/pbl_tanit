import 'package:flutter/material.dart';
import 'package:pbl_tanit/screens/admin/categories/category_edit_page.dart';
import 'package:pbl_tanit/screens/admin/categories/category_list_page.dart';
import 'package:pbl_tanit/screens/admin/dashboard/admin_dashboard.dart';
import 'package:pbl_tanit/screens/admin/users/user_list_page.dart';
import 'package:pbl_tanit/screens/admin/posts/post_list_page.dart';

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
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash_screen', // halaman awal
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
        '/admin/categories/edit': (context) => CategoryEditPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
