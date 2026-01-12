# 🔔 دليل نظام تذكير المزاج اليومي
## Mood Reminder System Guide

## ✅ ما تم إنجازه / What was completed

### 1. **إنشاء جدول إشعارات المستخدمين / User Notifications Table**
- جدول `user_notifications` في قاعدة البيانات
- دعم اللغتين العربية والإنجليزية
- تتبع حالة الإشعار (pending, sent, failed)

### 2. **نموذج بيانات UserNotification**
- `models/UserNotification.js`
- علاقة مع جدول المستخدمين
- حقول للعنوان والرسالة بالعربية والإنجليزية

### 3. **خدمة التذكير الذكية / Smart Reminder Service**
- `services/moodReminderService.js`
- تعمل كل دقيقتين (للاختبار - يمكن تغييرها)
- تتحقق من المستخدمين الذين لم يسجلوا مزاجهم اليوم
- دعم كامل للعربية والإنجليزية

### 4. **API endpoints جاهزة**
- `routes/userNotificationRoutes.js`
- `controllers/userNotificationController.js`
- مسجلة في `server.js` على `/api/user-notifications`

### 5. **التشغيل التلقائي**
- الخدمة تبدأ تلقائياً عند تشغيل الخادم
- تعمل في الخلفية باستمرار

---

## 🚀 كيفية الاختبار / How to Test

### 1. **تشغيل الخادم**
```bash
cd pureMood_backend/pureMood_backend
npm start
# أو node server.js
```

### 2. **التحقق من بدء الخدمة**
ابحث عن هذه الرسائل في الكونسول:
```
✅ user_notifications table created/verified
🚀 Mood reminder service auto-started
🚀 Starting mood reminder service - reminders every 2 minutes
```

### 3. **اختبار الAPI**
استخدم ملف `test_mood_reminders.http` أو Postman:

**جلب الإشعارات:**
```http
GET http://localhost:5000/api/user-notifications
Authorization: Bearer YOUR_JWT_TOKEN
```

**إرسال تذكير يدوي:**
```http
POST http://localhost:5000/api/user-notifications/mood-reminder
Authorization: Bearer YOUR_JWT_TOKEN
```

### 4. **تتبع الإشعارات في الكونسول**
ستظهر رسائل مثل:
```
🔍 Checking for mood reminders...
📝 Found 1 users needing mood reminders
✅ Mood reminder sent to اسم المستخدم (ID: 123)
```

---

## ⚙️ إعدادات الخدمة / Service Settings

### **للأدمن فقط:**

**حالة الخدمة:**
```http
GET /api/user-notifications/mood-reminder/settings
```

**تغيير فترة التذكير:**
```http
PUT /api/user-notifications/mood-reminder/interval
{
  "interval_minutes": 5
}
```

**إيقاف/تشغيل الخدمة:**
```http
POST /api/user-notifications/mood-reminder/stop
POST /api/user-notifications/mood-reminder/start
```

---

## 🧪 اختبار سريع / Quick Test

### إنشاء إشعار تجريبي:
```sql
-- في قاعدة البيانات مباشرة
INSERT INTO user_notifications (user_id, type, title_ar, title_en, message_ar, message_en, status, sent_at) 
VALUES (1, 'mood_reminder', 
        '🌟 حان وقت تسجيل مزاجك!', 
        '🌟 Time to Log Your Mood!', 
        'لم تسجل مزاجك اليوم بعد. خذ دقيقة لتسجيل مشاعرك.', 
        'You haven\'t logged your mood today yet. Take a minute to record your feelings.', 
        'sent', NOW());
```

### ثم جلب الإشعارات عبر API:
```http
GET http://localhost:5000/api/user-notifications
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🔧 استكشاف الأخطاء / Troubleshooting

### إذا لم تظهر الإشعارات:

1. **تحقق من الجدول:**
```sql
SELECT * FROM user_notifications WHERE user_id = YOUR_USER_ID;
```

2. **تحقق من حالة الخدمة:**
```http
GET /api/user-notifications/mood-reminder/settings
```

3. **تحقق من الكونسول:**
```
🔍 Checking for mood reminders...
📝 Found X users needing mood reminders
```

4. **تحقق من وجود المستخدم:**
```sql
SELECT user_id, name, status FROM users WHERE user_id = YOUR_USER_ID;
```

5. **تحقق من تسجيل المزاج اليوم:**
```sql
SELECT * FROM mood_entries WHERE user_id = YOUR_USER_ID 
AND DATE(created_at) = CURDATE();
```

---

## 🎯 الخطوات التالية / Next Steps

1. **تخصيص الرسائل** حسب المستخدم
2. **إضافة Push Notifications** (Firebase/OneSignal)
3. **إضافة SMS notifications**
4. **تحسين التوقيتات** (8 مساءً يومياً)
5. **إضافة إعدادات المستخدم** (تشغيل/إيقاف التذكيرات)

---

## 📱 التكامل مع التطبيق / App Integration

في التطبيق، استخدم هذه الـ endpoints:

```dart
// جلب الإشعارات
final response = await http.get(
  Uri.parse('$baseUrl/api/user-notifications'),
  headers: {'Authorization': 'Bearer $token'},
);

// تحديد كمقروء
await http.put(
  Uri.parse('$baseUrl/api/user-notifications/$notificationId/read'),
  headers: {'Authorization': 'Bearer $token'},
);
```

---

**✨ النظام جاهز للعمل الآن! 🎉**
