# 🔔 دليل إعداد نظام الإشعارات - Notification System Setup Guide

## ✅ ما تم إضافته

### 1. قاعدة البيانات (Database)
- ✅ **Model**: `models/Notification.js` - نموذج الإشعارات
- ✅ **Migration**: `migrations/create_notifications_table.sql` - ملف SQL لإنشاء الجدول

### 2. Backend Files
- ✅ **Controller**: `controllers/notificationController.js` - منطق الإشعارات
- ✅ **Routes**: `routes/notificationRoutes.js` - مسارات API
- ✅ **Server Integration**: تم تسجيل الـ routes في `server.js`

### 3. Triggers (محفزات الإشعارات)
تم إضافة إشعارات تلقائية عند:
1. ✅ **تسجيل admin أو specialist جديد** (`userController.js`)
2. ✅ **نشر منشور جديد** (`communityController.js`)
3. ✅ **حذف منشور من قبل admin** (`adminController.js`)

### 4. Documentation
- ✅ `docs/NOTIFICATIONS_API.md` - شرح كامل للـ API
- ✅ `docs/FLUTTER_INTEGRATION.md` - نماذج Flutter للتطبيق
- ✅ `docs/NOTIFICATION_SETUP.md` - هذا الملف

---

## 🚀 خطوات التشغيل

### الخطوة 1: إنشاء جدول الإشعارات

قم بتشغيل الأمر التالي في MySQL:

```bash
mysql -u your_username -p your_database < migrations/create_notifications_table.sql
```

أو افتح MySQL Workbench وقم بتنفيذ محتوى ملف `migrations/create_notifications_table.sql`

### الخطوة 2: إعادة تشغيل السيرفر

```bash
npm run dev
# أو
node server.js
```

### الخطوة 3: التحقق من التشغيل

افتح المتصفح أو Postman وجرب:

```
GET http://localhost:5000/api/notifications
Headers:
  Authorization: Bearer YOUR_ADMIN_TOKEN
```

---

## 🧪 اختبار النظام

### 1. اختبار إشعار التسجيل

```bash
POST http://localhost:5000/api/users/register
Content-Type: application/json

{
  "name": "Test Specialist",
  "email": "specialist@test.com",
  "password": "Test123!",
  "role": "specialist",
  "age": 30,
  "gender": "male"
}
```

**النتيجة المتوقعة:**
- سيتم إنشاء user بـ status = 'pending'
- سيتم إرسال إشعار لجميع الأدمن

### 2. اختبار إشعار المنشور

```bash
POST http://localhost:5000/api/community/posts
Authorization: Bearer USER_TOKEN
Content-Type: application/json

{
  "title": "Test Post",
  "content": "This is a test post",
  "category": "general",
  "is_anonymous": false
}
```

**النتيجة المتوقعة:**
- سيتم نشر المنشور
- سيتم إرسال إشعار لجميع الأدمن

### 3. اختبار جلب الإشعارات

```bash
GET http://localhost:5000/api/notifications
Authorization: Bearer ADMIN_TOKEN
```

**النتيجة المتوقعة:**
```json
{
  "notifications": [...],
  "unread_count": 2
}
```

---

## 📊 API Endpoints المتاحة

| Method | Endpoint | الوصف |
|--------|----------|------|
| GET | `/api/notifications` | جلب الإشعارات |
| GET | `/api/notifications/stats` | إحصائيات الإشعارات |
| PUT | `/api/notifications/:id/read` | تحديد إشعار كمقروء |
| PUT | `/api/notifications/read-all` | تحديد الكل كمقروء |
| DELETE | `/api/notifications/:id` | حذف إشعار |
| DELETE | `/api/notifications/read/all` | حذف المقروءة |

---

## 🎯 أنواع الإشعارات الحالية

1. **`new_user_pending`** - طلب تسجيل admin/specialist جديد
   ```javascript
   {
     type: "new_user_pending",
     title: "طلب تسجيل أخصائي جديد",
     message: "أحمد (ahmad@email.com) يطلب التسجيل...",
     data: { user_id, name, email, role }
   }
   ```

2. **`new_post`** - منشور جديد في المجتمع
   ```javascript
   {
     type: "new_post",
     title: "منشور جديد في المجتمع",
     message: "محمد نشر منشور جديد...",
     data: { post_id, user_id, title, category }
   }
   ```

3. **`post_deleted`** - حذف منشور
   ```javascript
   {
     type: "post_deleted",
     title: "تم حذف منشور",
     message: "تم حذف منشور 'العنوان'...",
     data: { post_id, title, deleted_by }
   }
   ```

---

## 🔧 إضافة نوع إشعار جديد

في أي controller، استورد `createNotification`:

```javascript
const { createNotification } = require('./notificationController');

// في دالتك
await createNotification(
  'notification_type',    // نوع الإشعار (مثل: user_banned)
  'العنوان',              // عنوان الإشعار
  'الرسالة التفصيلية',    // محتوى الإشعار
  { key: 'value' }        // بيانات إضافية
);
```

**مثال عملي:**

```javascript
// في حالة حظر مستخدم
await createNotification(
  'user_banned',
  'تم حظر مستخدم',
  `تم حظر المستخدم ${user.name} بسبب: ${reason}`,
  { 
    user_id: user.user_id, 
    banned_by: req.user.user_id,
    reason: reason 
  }
);
```

---

## 🎨 تخصيص النظام

### تغيير الحد الأقصى للإشعارات

في `notificationController.js`:

```javascript
const notifications = await Notification.findAll({
  where,
  order: [['created_at', 'DESC']],
  limit: 100 // غير هذا الرقم
});
```

### إضافة فلاتر إضافية

يمكنك إضافة فلاتر حسب `type` أو `date range`:

```javascript
// مثال: جلب إشعارات نوع معين
const { type } = req.query;
if (type) {
  where.type = type;
}
```

---

## 🔐 الأمان

- ✅ جميع الـ endpoints محمية بـ authentication
- ✅ فقط الأدمن يمكنهم الوصول للإشعارات
- ✅ كل admin يرى إشعاراته فقط
- ✅ لا يمكن للمستخدم العادي الوصول

---

## 📱 دمج Frontend

راجع ملف `docs/FLUTTER_INTEGRATION.md` للحصول على:
- Models كاملة للـ Dart
- NotificationService جاهز
- UI Screens جاهزة
- Notification Badge Widget

---

## ⚡ Performance Tips

1. **عمل Index على الأعمدة المهمة** (تم بالفعل في migration):
   ```sql
   INDEX idx_admin_id (admin_id)
   INDEX idx_is_read (is_read)
   INDEX idx_created_at (created_at)
   ```

2. **تنظيف الإشعارات القديمة** (optional):
   ```sql
   DELETE FROM notifications 
   WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY) 
   AND is_read = TRUE;
   ```

3. **Pagination للإشعارات الكثيرة**:
   ```javascript
   const { page = 1, limit = 20 } = req.query;
   const offset = (page - 1) * limit;
   
   const notifications = await Notification.findAll({
     where,
     order: [['created_at', 'DESC']],
     limit: parseInt(limit),
     offset: parseInt(offset)
   });
   ```

---

## 🐛 Troubleshooting

### مشكلة: "Table 'notifications' doesn't exist"
**الحل:** قم بتشغيل ملف migration:
```bash
mysql -u root -p database_name < migrations/create_notifications_table.sql
```

### مشكلة: "Cannot read property 'createNotification'"
**الحل:** تأكد من أن import صحيح:
```javascript
const { createNotification } = require('./notificationController');
```

### مشكلة: الإشعارات لا تظهر
**الحل:** 
1. تأكد أن المستخدم role = 'admin'
2. تأكد أن status = 'accepted'
3. تحقق من الـ console logs

---

## 📝 TODO - تحسينات مستقبلية

- [ ] Push Notifications (FCM)
- [ ] Email Notifications
- [ ] Notification Preferences (تفضيلات المستخدم)
- [ ] Real-time notifications (WebSockets/Socket.io)
- [ ] Notification Templates
- [ ] Notification Scheduling
- [ ] Multi-language support
- [ ] Notification Analytics

---

## 💡 نصائح

1. **استخدم الإشعارات بحكمة**: لا ترسل إشعارات كثيرة جداً
2. **اجعل الرسائل واضحة**: العنوان والمحتوى يجب أن يكونا مفهومين
3. **أضف بيانات مفيدة**: استخدم حقل `data` لإضافة معلومات إضافية
4. **نظف الإشعارات القديمة**: احذف الإشعارات المقروءة القديمة دورياً

---

## 📞 الدعم

إذا واجهت أي مشكلة، تحقق من:
- Console logs في السيرفر
- Network tab في المتصفح
- Database logs
- ملفات الـ documentation

---

**تم إعداده بواسطة:** PureMood Team  
**التاريخ:** 2024  
**الإصدار:** 1.0.0
