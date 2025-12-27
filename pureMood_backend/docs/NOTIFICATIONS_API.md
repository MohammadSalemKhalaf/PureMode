# 🔔 Notification System API - نظام الإشعارات

## نظرة عامة
نظام إشعارات شامل للأدمن لتتبع الأحداث الهامة في التطبيق مثل:
- تسجيل مستخدمين جدد (أدمن/أخصائي) يحتاجون موافقة
- منشورات جديدة في المجتمع
- أي أحداث أخرى مهمة

## Base URL
```
/api/notifications
```

**ملاحظة:** جميع endpoints تحتاج توثيق كأدمن (admin role)

---

## 📋 Endpoints

### 1. جلب الإشعارات
```http
GET /api/notifications
```

**Query Parameters:**
- `unread_only` (optional): `true` لجلب الإشعارات غير المقروءة فقط

**Response:**
```json
{
  "notifications": [
    {
      "notification_id": 1,
      "admin_id": 5,
      "type": "new_user_pending",
      "title": "طلب تسجيل أخصائي جديد",
      "message": "أحمد محمد (ahmad@email.com) يطلب التسجيل كـ أخصائي ويحتاج موافقتك",
      "data": {
        "user_id": 123,
        "name": "أحمد محمد",
        "email": "ahmad@email.com",
        "role": "specialist"
      },
      "is_read": false,
      "created_at": "2024-01-15T10:30:00.000Z"
    }
  ],
  "unread_count": 5
}
```

---

### 2. إحصائيات الإشعارات
```http
GET /api/notifications/stats
```

**Response:**
```json
{
  "total": 45,
  "unread": 12,
  "recent_24h": 8
}
```

---

### 3. تحديد إشعار كمقروء
```http
PUT /api/notifications/:notification_id/read
```

**Response:**
```json
{
  "message": "Notification marked as read"
}
```

---

### 4. تحديد كل الإشعارات كمقروءة
```http
PUT /api/notifications/read-all
```

**Response:**
```json
{
  "message": "All notifications marked as read"
}
```

---

### 5. حذف إشعار
```http
DELETE /api/notifications/:notification_id
```

**Response:**
```json
{
  "message": "Notification deleted successfully"
}
```

---

### 6. حذف كل الإشعارات المقروءة
```http
DELETE /api/notifications/read/all
```

**Response:**
```json
{
  "message": "All read notifications deleted successfully"
}
```

---

## 📌 أنواع الإشعارات (Notification Types)

### 1. `new_user_pending`
يتم إرساله عند تسجيل admin أو specialist جديد يحتاج موافقة

**Data Structure:**
```json
{
  "user_id": 123,
  "name": "اسم المستخدم",
  "email": "email@example.com",
  "role": "admin | specialist"
}
```

### 2. `new_post`
يتم إرساله عند نشر منشور جديد في المجتمع

**Data Structure:**
```json
{
  "post_id": 456,
  "user_id": 123,
  "title": "عنوان المنشور",
  "category": "general | support | advice",
  "is_anonymous": false
}
```

---

## 🔧 كيفية إضافة إشعارات جديدة

في أي controller تريد إرسال إشعار منه:

```javascript
const { createNotification } = require('./notificationController');

// مثال: إرسال إشعار عند حدث معين
await createNotification(
  'notification_type',           // نوع الإشعار
  'عنوان الإشعار',              // العنوان
  'محتوى الإشعار التفصيلي',     // الرسالة
  { key: 'value' }               // بيانات إضافية (optional)
);
```

---

## 💡 أمثلة الاستخدام

### جلب الإشعارات غير المقروءة فقط
```bash
GET /api/notifications?unread_only=true
Authorization: Bearer YOUR_ADMIN_TOKEN
```

### تحديد إشعار معين كمقروء
```bash
PUT /api/notifications/15/read
Authorization: Bearer YOUR_ADMIN_TOKEN
```

---

## 🗄️ Database Schema

### Table: `notifications`
```sql
CREATE TABLE notifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSON,
  is_read BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE CASCADE
);
```

---

## 📱 Integration مع Frontend

### مثال Flutter/Dart:

```dart
Future<List<Notification>> getNotifications({bool unreadOnly = false}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/notifications${unreadOnly ? '?unread_only=true' : ''}'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // معالجة الاستجابة
}

Future<void> markAsRead(int notificationId) async {
  await http.put(
    Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
    headers: {'Authorization': 'Bearer $token'},
  );
}
```

---

## ✅ Features المتوفرة

- ✅ إشعارات تلقائية للأدمن
- ✅ تصنيف الإشعارات حسب النوع
- ✅ عداد الإشعارات غير المقروءة
- ✅ تحديد إشعار واحد أو كل الإشعارات كمقروءة
- ✅ حذف إشعار واحد أو كل الإشعارات المقروءة
- ✅ إحصائيات الإشعارات
- ✅ حد أقصى 100 إشعار لتحسين الأداء
- ✅ ترتيب تنازلي (الأحدث أولاً)

---

## 🎯 الأحداث التي تولد إشعارات حالياً

1. **تسجيل مستخدم جديد** (admin/specialist)
   - File: `userController.js` → `register()`
   - Type: `new_user_pending`

2. **منشور جديد في المجتمع**
   - File: `communityController.js` → `createPost()`
   - Type: `new_post`

---

## 📝 ملاحظات

- كل الإشعارات تُرسل لجميع الأدمن المقبولين (status = 'accepted')
- الإشعارات محدودة بـ 100 إشعار لكل طلب
- يمكن إضافة أنواع إشعارات جديدة بسهولة
- يمكن توسيع النظام ليشمل إشعارات push notifications مستقبلاً
