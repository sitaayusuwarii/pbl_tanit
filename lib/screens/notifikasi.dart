import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_tanit/screens/detail_post.dart';
import 'package:pbl_tanit/screens/profile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  _NotifikasiPageState createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<dynamic> notifications = [];
  bool isLoading = false;
  String selectedFilter = 'semua';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

 Future<void> fetchNotifications({String? filter}) async {
  setState(() => isLoading = true);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  try {
    String url = '${AppConfig.baseUrl}/notifications';

    if (filter != null && filter != 'semua') {
      url += '?type=$filter';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        notifications = jsonDecode(response.body);
      });
    } else {
      debugPrint('Gagal load notifikasi: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error fetchNotifications: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

String fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${AppConfig.storageUrl}$url';
}

void _deleteWithUndo(Map<String, dynamic> notif) {
  final index = notifications.indexOf(notif);

  setState(() {
    notifications.removeAt(index);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Notifikasi dihapus'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            notifications.insert(index, notif);
          });
        },
      ),
      duration: const Duration(seconds: 3),
    ),
  );

  Future.delayed(const Duration(seconds: 3), () {
    if (!notifications.contains(notif)) {
      _deleteNotification(notif['id']);
    }
  });
}

void _confirmDeleteAll() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus semua notifikasi?'),
      content: const Text('Tindakan ini tidak bisa dibatalkan.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('BATAL'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _deleteAllNotifications();
          },
          child: const Text(
            'HAPUS',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteAllNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  await http.delete(
    Uri.parse('${AppConfig.baseUrl}/notifications'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  setState(() {
    notifications.clear();
  });
}


Future<void> _deleteNotification(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  await http.delete(
    Uri.parse('${AppConfig.baseUrl}/notifications/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
}


Future<void> _followUser(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  await http.post(
    Uri.parse('${AppConfig.baseUrl}/follow/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
}


Future<void> markAsRead(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  await http.post(
    Uri.parse('${AppConfig.baseUrl}/notifications/$id/read'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
}

  // Future<void> markAsRead(int id) async {
  //   print("Mark as read $id");
  // }

  // Future<void> markAllAsRead() async {
  //   print("Mark all as read");
  // }

  void onFilterChanged(String filter) {
    setState(() => selectedFilter = filter);
    fetchNotifications(filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Notifikasi',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  elevation: 0,
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete_all') {
          _confirmDeleteAll();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete_all',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus semua notifikasi'),
            ],
          ),
        ),
      ],
    ),
  ],
),

      body: Column(
        children: [
          // FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Like', 'like'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Komentar', 'comment'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Koneksi', 'follow'),
                ],
              ),
            ),
          ),

          // LIST ISI
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () =>
                            fetchNotifications(filter: selectedFilter),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(notifications[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
  bool selected = (selectedFilter == value);

  return InkWell(
    onTap: () => onFilterChanged(value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.green : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}


Future<Map<String, dynamic>?> fetchPost(int postId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final res = await http.get(
    Uri.parse('${AppConfig.baseUrl}/posts/$postId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return null;
}

String timeAgo(String value) {
  // 🚑 kalau sudah berupa "7 minutes ago"
  if (value.contains('ago')) {
    return value;
  }

  try {
    final time = DateTime.parse(value).toLocal();
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik yang lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  } catch (e) {
    return value; // fallback
  }
}

Widget _followButton({
  required int userId,
  required Map<String, dynamic>? follow,
}) {
  if (follow == null) return const SizedBox();

  final isFollowing = follow['is_following_back'] == true;

  return SizedBox(
    height: 32,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey[300] : Colors.green,
        foregroundColor: isFollowing ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: isFollowing
          ? null
          : () async {
              await _followUser(userId);
              setState(() {
                follow['is_following_back'] = true;
              });
            },
      child: Text(
        isFollowing ? 'Mengikuti' : 'Ikuti balik',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}



 Widget _buildNotificationCard(Map<String, dynamic> notif) {
  final isRead = notif['is_read'] == true;
  final fromUser = notif['from_user'];
  final post = notif['post'];
  final isFollowNotif = notif['type'] == 'follow';

  return Dismissible(
    key: ValueKey(notif['id']),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    onDismissed: (_) => _deleteWithUndo(notif),

    // ✅ CHILD DARI DISMISSIBLE
    child: InkWell(
      onTap: () {
        markAsRead(notif['id']);
        setState(() => notif['is_read'] = true);

        // 🔔 FOLLOW → PROFILE
        if (isFollowNotif) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(
                userId: fromUser['id'],
              ),
            ),
          );
          return;
        }

        // 🖼 POST → DETAIL
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPostPage(
              post: post,
              currentUserId: null,
              likedPostIds: {},
              onLikeToggle: (_) {},
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  fixImageUrl(fromUser?['avatar_url']).isNotEmpty
                      ? NetworkImage(fixImageUrl(fromUser?['avatar_url']))
                      : const AssetImage('assets/avatar_default.png')
                          as ImageProvider,
            ),

            const SizedBox(width: 12),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(
                          text: fromUser?['name'] ?? 'User',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: isFollowNotif
                              ? ' mulai mengikuti Anda'
                              : notif['type'] == 'like'
                                  ? ' menyukai postingan Anda'
                                  : ' mengomentari postingan Anda',
                        ),
                        if (notif['type'] == 'comment')
                          TextSpan(
                            text: notif['comment'] ?? '',
                            style: const TextStyle(color: Colors.black87),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notif['created_at'] != null
                        ? timeAgo(notif['created_at'])
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // KANAN: FOLLOW BUTTON / POST IMAGE
            if (isFollowNotif)
              _followButton(
                userId: fromUser['id'],
                follow: notif['follow'],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: fixImageUrl(post?['image_url']).isNotEmpty
                    ? Image.network(
                        fixImageUrl(post?['image_url']),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 20),
                      ),
              ),
          ],
        ),
      ),
    ),
  );
}



Widget _postPlaceholder() {
  return Container(
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported, size: 20),
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada notifikasi",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
