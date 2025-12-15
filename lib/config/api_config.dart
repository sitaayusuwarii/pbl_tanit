class ApiConfig {
  // GANTI IP SESUAI IP LAPTOP SAAT INI
  // Pastikan HP dan Laptop konek di WiFi yang sama!

  static const String _ipAddress = "lastest.ip.address.here";
  static const String _port = "8000";
  
  // Base URL otomatis gabungin IP + Port + /api
  static const String baseUrl = "http://$_ipAddress:$_port/api";
  
  // URL untuk Gambar (jika nanti butuh load gambar dari public folder)
  static const String imageUrl = "http://$_ipAddress:$_port/storage";
}