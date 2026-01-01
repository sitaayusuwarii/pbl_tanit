import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class AdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const AdminAppBar({
    Key? key,
    required this.title,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  State<AdminAppBar> createState() => _AdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminAppBarState extends State<AdminAppBar> {
  // 2. Variabel untuk menyimpan Nama dan Role
  String _userName = 'Loading...';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 3. Panggil fungsi load saat widget dibuat
  }

  // 4. Fungsi mengambil data dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil nama user (default: 'Admin User' jika null)
      _userName = prefs.getString('name') ?? 'Admin User';
      
      // Ambil role user (default: 'admin' jika null)
      String rawRole = prefs.getString('role') ?? 'admin';
      
      // Format role biar cantik (misal: 'super_admin' jadi 'SUPER ADMIN')
      _userRole = rawRole.replaceAll('_', ' ').toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: widget.onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 5. Tampilkan Nama User Dinamis
                  Text(
                    _userName, // <-- Variabel Nama
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 6. Tampilkan Role User Dinamis
                  Text(
                    _userRole, // <-- Variabel Role
                    style: const TextStyle(
                      color: Colors.green, // Ubah warna biar beda dikit
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.green.shade600,
                child: Text(
                  // 7. Ambil huruf depan nama user (Inisial)
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}