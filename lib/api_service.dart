import 'package:http/http.dart' as http;
import 'dart:typed_data';

Future<void> uploadPost(Uint8List imageBytes, String description, String category, String token) async {
  var request = http.MultipartRequest('POST', Uri.parse('http://10.11.3.86:8000/api/posts'));
  request.headers['Authorization'] = 'Bearer $token';

  request.fields['description'] = description;
  request.fields['category'] = category;

  if (imageBytes != null) {
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'upload.png',
    ));
  }

  var response = await request.send();
  if (response.statusCode == 201) {
    print('Upload berhasil');
  } else {
    print('Upload gagal: ${response.statusCode}');
  }
}
