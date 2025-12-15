import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin {
  
  // GEMINI API KEY
  static const String _apiKey = ''; 
  
  late final GenerativeModel _model;
  late ChatSession _chatSession;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _messages = []; 
  List<Map<String, dynamic>> _history = [];
  
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  XFile? _selectedImage;

  int? _activeHistoryIndex; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
    _startNewSession(); 
    _loadHistory();     
  }

  // --- LOGIKA LOAD & SAVE HISTORY ---

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('chat_history');

    if (historyString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyString);
        setState(() {
          _history = decoded.map((item) {
            return {
              'title': item['title'],
              'preview': item['preview'],
              'date': DateTime.parse(item['date']),
              'messages': item['messages'] ?? [], 
            };
          }).toList();
        });
      } catch (e) {
        debugPrint("Error loading history: $e");
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    final encodedData = _history.map((item) {
      return {
        'title': item['title'],
        'preview': item['preview'],
        'date': item['date'].toString(),
        'messages': item['messages'], 
      };
    }).toList();

    await prefs.setString('chat_history', jsonEncode(encodedData));
  }

  // --- LOGIKA HAPUS (BARU) ---
  
  void _deleteHistoryItem(int index) {
    setState(() {
      _history.removeAt(index); // Hapus dari list
    });
    _saveHistory(); // Simpan perubahan ke HP
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percakapan berhasil dihapus'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Percakapan?'),
        content: const Text('Percakapan ini akan hilang permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup popup
              _deleteHistoryItem(index); // Hapus data
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // LOGIKA RESTORE
  // Tambahkan parameter 'index' di sini
  void _restoreChatSession(Map<String, dynamic> historyItem, int index) { 
    List<dynamic> rawMessages = historyItem['messages'];

    setState(() {
      _activeHistoryIndex = index; // SIMPAN INDEX CHAT YANG DIBUKA

      _messages = rawMessages.map((m) {
        return {
          'role': m['role'],
          'text': m['text'],
          'image': m['image'],
          'time': DateTime.parse(m['time']),
        };
      }).toList();

      // Kode konversi context Gemini
      List<Content> historyContent = [];
      for (var msg in _messages) {
        if (msg['role'] == 'user') {
          historyContent.add(Content.text(msg['text']));
        } else {
          historyContent.add(Content.model([TextPart(msg['text'])]));
        }
      }

      _chatSession = _model.startChat(history: [
        Content.text('Kamu adalah Asisten Pertanian yang cerdas. Bantu petani.'),
        ...historyContent 
      ]);

      _tabController.animateTo(0);
    });
  }

  void _startNewSession() {
    setState(() {
      _activeHistoryIndex = null;
      _messages.clear();
      _chatSession = _model.startChat(history: [
        Content.text('Kamu adalah Asisten Pertanian yang cerdas. Bantu petani.'),
      ]);
    });
  }

  // --- LOGIKA GAMBAR & PESAN ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70, 
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage([String? value]) async {
    final text = value ?? _ctrl.text.trim();
    final bool hasImage = _selectedImage != null;

    if (text.isEmpty && !hasImage) return;

    final String? localImagePath = _selectedImage?.path;
    Uint8List? imageBytes;

    if (hasImage) {
      imageBytes = await _selectedImage!.readAsBytes();
    }

    setState(() {
      _messages.add({
        'role': 'user', 
        'text': text, 
        'image': localImagePath, 
        'time': DateTime.now()
      });
      _sending = true;
      _selectedImage = null; 
    });
    
    _ctrl.clear();
    _scrollToEnd();

    try {
      GenerateContentResponse response;

      if (imageBytes != null) {
        final content = Content.multi([
          if (text.isNotEmpty) TextPart(text),
          DataPart('image/jpeg', imageBytes),
        ]);
        response = await _chatSession.sendMessage(content);
      } else {
        response = await _chatSession.sendMessage(Content.text(text));
      }

      final botText = response.text ?? 'Maaf, saya tidak bisa memberikan jawaban saat ini.';

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': botText,
            'time': DateTime.now()
          });
          _sending = false;
        });
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': 'Terjadi kesalahan koneksi: $e',
            'time': DateTime.now()
          });
          _sending = false;
        });
        _scrollToEnd();
      }
    }
  }

  void _archiveChatAndReset() {
    if (_messages.isEmpty) return;

    setState(() {
      String title = 'Percakapan Baru';
      String preview = 'Tidak ada detail';

      final userMsgs = _messages.where((m) => m['role'] == 'user').toList();
      if (userMsgs.isNotEmpty) {
        title = userMsgs.first['text'];
        if (title.isEmpty) title = "Analisis Gambar";
        if (title.length > 30) title = '${title.substring(0, 30)}...'; // Persingkat judul
        preview = _messages.last['text'] ?? '';
      }

      final messagesToSave = _messages.map((m) {
        return {
          'role': m['role'],
          'text': m['text'],
          'image': m['image'],
          'time': m['time'].toString(), 
        };
      }).toList();

      final newHistoryItem = {
        'title': title,
        'preview': preview,
        'date': DateTime.now(),
        'messages': messagesToSave, 
      };

      if (_activeHistoryIndex != null) {
        // Jika sedang buka chat lama: Hapus yang lama dulu
        _history.removeAt(_activeHistoryIndex!);
        // Lalu masukkan versi terbaru ke paling atas (biar jadi 'Recent')
        _history.insert(0, newHistoryItem);
      } else {
        // Jika chat baru: Langsung masukkan ke atas
        _history.insert(0, newHistoryItem);
      }
      
      _startNewSession(); // Reset jadi chat baru lagi
      _selectedImage = null;
    });

    _saveHistory(); 

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percakapan disimpan'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(time);
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM').format(time);
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asisten Pertanian',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                'Powered by Gemini AI',
                                style: TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_tabController.index == 0)
                          IconButton(
                            icon: const Icon(Icons.add_comment_outlined),
                            color: const Color(0xFF2E7D32),
                            tooltip: 'Simpan & Chat Baru',
                            onPressed: _archiveChatAndReset,
                          ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    onTap: (index) {
                        setState(() {}); 
                    },
                    labelColor: const Color(0xFF2E7D32),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF2E7D32),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Chatbot'),
                      Tab(text: 'Riwayat'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // LIST PESAN
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          size: 60,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Halo Petani Cerdas!',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tanyakan masalah pertanian di sini',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildChatBubble(_messages[i]),
                ),
        ),
        
        // INDIKATOR MENGETIK
        if (_sending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(),
                  const SizedBox(width: 4),
                  _buildTypingDot(delay: 200),
                  const SizedBox(width: 4),
                  _buildTypingDot(delay: 400),
                ],
              ),
            ),
          ),

        // INPUT AREA
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // PREVIEW GAMBAR
                if (_selectedImage != null)
                 Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!)
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Gambar Siap Dikirim",
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        )
                      ],
                    ),
                  ),

                // BARIS INPUT UTAMA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // TOMBOL TAMBAH GAMBAR
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add_photo_alternate_outlined, 
                            color: Colors.grey[700], size: 22),
                          onPressed: _sending ? null : _showImagePickerModal,
                          tooltip: 'Tambah Gambar',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      
                      // TEXT FIELD
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: _selectedImage != null 
                                  ? 'Tambahkan keterangan (opsional)...' 
                                  : 'Ketik pertanyaan...',
                              hintStyle: TextStyle(
                                fontFamily: 'PublicSans',
                                color: Colors.grey[500],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) => _sendMessage(value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // TOMBOL KIRIM
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _sending ? null : () => _sendMessage(),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET CHAT BUBBLE
  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] ?? '';
    final String? imagePath = msg['image'];

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 12,
        right: isUser ? 12 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2E7D32) : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                           return Container(
                             height: 100,
                             width: double.infinity,
                             color: Colors.grey[300],
                             child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                           );
                        },
                      ),
                    ),
                  ),

                if (text.isNotEmpty)
                  MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 15,
                        color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatTime(msg['time'] is String ? DateTime.parse(msg['time']) : msg['time'] ?? DateTime.now()),
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB RIWAYAT (YANG SUDAH ADA TOMBOL SAMPAH) ---
  Widget _buildHistoryTab() {
    return _history.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Riwayat',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Percakapan Anda akan disimpan di sini',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  
                  // Ikon Chat di Kiri
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.forum_outlined,
                        color: Color(0xFF2E7D32)),
                  ),
                  
                  // Judul dan Preview
                  title: Text(
                    item['title'],
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        item['preview'],
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(DateTime.parse(item['date'].toString())),
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  
                  // 🔥 TOMBOL SAMPAH (HAPUS) 🔥
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Hapus Chat',
                    onPressed: () {
                      _showDeleteConfirmation(index);
                    },
                  ),
                  
                  // Klik Badan Chat = Buka
                  onTap: () {
                    _restoreChatSession(item, index);
                  },
                ),
              );
            },
          );
  }

  Widget _buildTypingDot({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400]!.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}