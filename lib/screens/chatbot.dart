import 'dart:convert'; // TAMBAHAN 1: Untuk convert data ke text (JSON)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHAN 2: Plugin penyimpanan

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin {
  
  static const String _apiKey = 'API_KEY_KAMU_DISINI'; // Pastikan API Key benar
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  late TabController _tabController;
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _history = []; // Hapus 'final' agar bisa di-overwrite saat load data

  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _startNewSession();
    
    _loadHistory(); // TAMBAHAN 3: Panggil fungsi load saat aplikasi dibuka
  }

  // --- FUNGSI BARU UNTUK LOAD DATA DARI HP ---
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('chat_history');

    if (historyString != null) {
      // Decode dari Text JSON kembali ke List
      final List<dynamic> decoded = jsonDecode(historyString);
      
      setState(() {
        _history = decoded.map((item) {
          return {
            'title': item['title'],
            'preview': item['preview'],
            // Convert String kembali ke DateTime
            'date': DateTime.parse(item['date']),
          };
        }).toList();
      });
    }
  }

  // --- FUNGSI BARU UNTUK SAVE DATA KE HP ---
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert DateTime ke String agar bisa disimpan sebagai JSON
    final encodedData = _history.map((item) {
      return {
        'title': item['title'],
        'preview': item['preview'],
        'date': item['date'].toString(), // DateTime jadi String
      };
    }).toList();

    // Simpan sebagai text JSON
    await prefs.setString('chat_history', jsonEncode(encodedData));
  }

  void _startNewSession() {
    setState(() {
      _chatSession = _model.startChat(history: [
        Content.text('Kamu adalah Asisten Pertanian yang cerdas dan ramah. '
            'Bantu petani dengan solusi praktis, singkat, dan mudah dipahami. '
            'Gunakan format Markdown (tebal, list) untuk memperjelas jawaban. '
            'Gunakan Bahasa Indonesia.'),
      ]);
    });
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

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM').format(time);
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
        preview = _messages.last['text'];
      }

      _history.insert(0, {
        'title': title,
        'preview': preview,
        'date': DateTime.now(),
      });

      _messages.clear();
      _startNewSession();
    });

    // TAMBAHAN 4: Simpan ke HP setiap kali menambah history
    _saveHistory(); 

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percakapan disimpan ke Riwayat'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _sendMessage([String? value]) async {
    final text = value ?? _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'time': DateTime.now()});
      _sending = true;
    });
    _ctrl.clear();
    _scrollToEnd();

    try {
      final response = await _chatSession.sendMessage(
        Content.text(text),
      );

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
            'text': 'Terjadi kesalahan koneksi atau API Key belum diatur.',
            'time': DateTime.now()
          });
          _sending = false;
        });
        _scrollToEnd();
      }
      debugPrint('Gemini Error: $e');
    }
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] ?? '';

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
            child: MarkdownBody(
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
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatTime(msg['time'] ?? DateTime.now()),
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

  Widget _buildChatTab() {
    return Column(
      children: [
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
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
                          hintText: 'Ketik pertanyaan...',
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
                  Container(
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
                          width: 48,
                          height: 48,
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
          ),
        ),
      ],
    );
  }

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
                       offset: const Offset(0,2)
                    )
                  ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.forum_outlined,
                        color: Color(0xFF2E7D32)),
                  ),
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
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item['date']),
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                  onTap: () {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                            tooltip: 'Chat Baru',
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
}