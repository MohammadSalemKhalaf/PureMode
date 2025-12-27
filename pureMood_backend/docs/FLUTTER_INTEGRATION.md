# 📱 Flutter Integration - دمج الإشعارات مع Flutter

## نموذج البيانات (Model)

### Notification Model
```dart
class NotificationModel {
  final int notificationId;
  final int adminId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.adminId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'],
      adminId: json['admin_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList(),
      unreadCount: json['unread_count'],
    );
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final int recent24h;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.recent24h,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'],
      unread: json['unread'],
      recent24h: json['recent_24h'],
    );
  }
}
```

---

## خدمة الإشعارات (Service)

### NotificationService
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  final String baseUrl;
  final String token;

  NotificationService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // جلب الإشعارات
  Future<NotificationResponse> getNotifications({bool unreadOnly = false}) async {
    final url = '$baseUrl/api/notifications${unreadOnly ? '?unread_only=true' : ''}';
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return NotificationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // جلب إحصائيات الإشعارات
  Future<NotificationStats> getNotificationStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return NotificationStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load notification stats');
    }
  }

  // تحديد إشعار كمقروء
  Future<void> markAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  // تحديد كل الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(int notificationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notifications/$notificationId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }

  // حذف كل الإشعارات المقروءة
  Future<void> deleteAllReadNotifications() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notifications/read/all'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete read notifications');
    }
  }
}
```

---

## واجهة الإشعارات (UI)

### NotificationsScreen
```dart
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      baseUrl: 'http://your-server-url',
      token: 'your-admin-token',
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _notificationService.getNotifications(
        unreadOnly: _showUnreadOnly,
      );
      setState(() {
        _notifications = response.notifications;
        _unreadCount = response.unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الإشعارات: $e')),
      );
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الإشعار: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الإشعارات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
        actions: [
          if (_unreadCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.mark_email_read),
                  onPressed: _markAllAsRead,
                  tooltip: 'تحديد الكل كمقروء',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('كل الإشعارات'),
                value: false,
              ),
              PopupMenuItem(
                child: Text('غير المقروءة فقط'),
                value: true,
              ),
            ],
            onSelected: (value) {
              setState(() => _showUnreadOnly = value);
              _loadNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onMarkAsRead: () => _markAsRead(notification.notificationId),
                      );
                    },
                  ),
                ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // التعامل مع نوع الإشعار والانتقال للصفحة المناسبة
    switch (notification.type) {
      case 'new_user_pending':
        // الانتقال لصفحة الموافقة على المستخدمين
        Navigator.pushNamed(context, '/admin/pending-users');
        break;
      case 'new_post':
        // الانتقال لصفحة المنشور
        final postId = notification.data?['post_id'];
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        }
        break;
      default:
        // عرض تفاصيل الإشعار
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('حسناً'),
              ),
            ],
          ),
        );
    }
    
    if (!notification.isRead) {
      _markAsRead(notification.notificationId);
    }
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'new_user_pending':
        return Icons.person_add;
      case 'new_post':
        return Icons.article;
      case 'post_deleted':
        return Icons.delete;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'new_user_pending':
        return Colors.blue;
      case 'new_post':
        return Colors.green;
      case 'post_deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(),
          child: Icon(_getIcon(), color: Colors.white),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? IconButton(
                icon: Icon(Icons.mark_email_read, color: Colors.blue),
                onPressed: onMarkAsRead,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
```

---

## Badge للإشعارات غير المقروءة

```dart
class NotificationBadge extends StatefulWidget {
  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // تحديث العداد كل دقيقة
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _loadUnreadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final service = NotificationService(
        baseUrl: 'http://your-server-url',
        token: 'your-admin-token',
      );
      final stats = await service.getNotificationStats();
      setState(() => _unreadCount = stats.unread);
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications').then((_) {
              _loadUnreadCount();
            });
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## استخدام في AppBar

```dart
AppBar(
  title: Text('لوحة التحكم'),
  actions: [
    NotificationBadge(),
    // ... other actions
  ],
)
```
