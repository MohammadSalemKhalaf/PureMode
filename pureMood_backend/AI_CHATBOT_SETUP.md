# AI Chatbot Setup - Quick Start Guide

## ✅ ما تم إضافته

### الباك إند (Node.js)
1. **نماذج Sequelize**:
   - `models/ChatSession.js` - جلسات المحادثة
   - `models/ChatMessage.js` - الرسائل

2. **خدمة OpenAI**:
   - `services/aiService.js` - اتصال OpenAI مع حواجز الأمان

3. **Controller و Routes**:
   - `controllers/aiController.js` - 4 endpoints جديدة
   - `routes/aiRoutes.js` - مُحدّث بالـ endpoints

4. **ملفات التهيئة**:
   - `.env.example` - قالب متغيرات البيئة
   - `migrations/create_chat_tables.sql` - إنشاء الجداول

5. **التوثيق**:
   - `docs/AI_CHAT_API.md` - توثيق الـ API
   - `docs/FLUTTER_INTEGRATION_GUIDE.md` - دليل التكامل مع Flutter

---

## 🚀 خطوات التشغيل

### 1. تثبيت المكتبات
```bash
npm install
```

### 2. تهيئة البيئة
```bash
# نسخ ملف البيئة
cp .env.example .env

# افتح .env وأضف:
OPENAI_API_KEY=sk-your-actual-openai-key-here
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=500
```

### 3. إنشاء الجداول
```bash
# الدخول لـ MySQL
mysql -u root -p

# اختيار قاعدة البيانات
USE puremood_db;

# تنفيذ migration
source migrations/create_chat_tables.sql;

# أو:
mysql -u root -p puremood_db < migrations/create_chat_tables.sql
```

### 4. تشغيل السيرفر
```bash
npm run dev
```

---

## 🧪 اختبار الـ Endpoints

### 1. POST `/api/ai/chat` - إرسال رسالة
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "ar",
    "messages": [{"role":"user","content":"نصيحة للاسترخاء؟"}],
    "consent": true
  }'
```

### 2. GET `/api/ai/sessions` - قائمة الجلسات
```bash
curl http://localhost:3000/api/ai/sessions \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. GET `/api/ai/sessions/:id/messages` - رسائل جلسة
```bash
curl http://localhost:3000/api/ai/sessions/1/messages \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. DELETE `/api/ai/sessions/:id` - حذف جلسة
```bash
curl -X DELETE http://localhost:3000/api/ai/sessions/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📱 التكامل مع Flutter

راجع الدليل الكامل في:
```
docs/FLUTTER_INTEGRATION_GUIDE.md
```

**الملخص السريع**:
1. إضافة `models/chat_session.dart` و `chat_message.dart`
2. إضافة `services/ai_chat_service.dart`
3. إضافة `screens/chat_screen.dart`
4. إضافة تبويب "المساعد" في الـ Bottom Navigation
5. إضافة زر "اسأل المساعد" بعد نتائج التقييم

---

## 🔒 ميزات الأمان

- ✅ **غير تشخيصي**: لا يقدم تشخيصات طبية أو توصيات دوائية
- ✅ **كشف الأزمات**: يكتشف كلمات مؤشرات الخطر ويوجّه لطلب مساعدة فورية
- ✅ **حواجز الأمان**: System prompts تمنع الاستخدام الخاطئ
- ✅ **إخلاء مسؤولية**: كل رد يتضمن تنويه واضح
- ✅ **موافقة المستخدم**: حفظ المحادثات يتطلب موافقة صريحة
- ✅ **حذف يدوي**: المستخدم يتحكم بحذف محادثاته

---

## 📊 الجداول المُنشأة

### `chat_sessions`
- `session_id` (PK)
- `user_id` (FK → users.user_id)
- `title` (أول رسالة مختصرة)
- `language` (ar/en)
- `consent` (موافقة الحفظ)
- `archived` (soft delete)
- `created_at`, `updated_at`

### `chat_messages`
- `message_id` (PK)
- `session_id` (FK → chat_sessions)
- `role` (user/assistant/system)
- `content` (نص الرسالة)
- `safety_flags` (JSON)
- `created_at`

---

## 🌐 الـ Endpoints المتاحة

| Method | Endpoint | الوصف |
|--------|----------|-------|
| POST | `/api/ai/chat` | إرسال رسالة وإنشاء/متابعة جلسة |
| GET | `/api/ai/sessions` | قائمة جلسات المستخدم |
| GET | `/api/ai/sessions/:id/messages` | رسائل جلسة محددة |
| DELETE | `/api/ai/sessions/:id` | حذف جلسة |

---

## 💰 تكاليف OpenAI (تقديرية)

باستخدام `gpt-4o-mini`:
- Input: ~$0.15 / 1M tokens
- Output: ~$0.60 / 1M tokens

**مثال**:
- رسالة مستخدم: ~50 tokens
- رد AI: ~200 tokens
- **التكلفة لكل رسالة**: ~$0.00013 (أقل من سنت واحد)

---

## 🐛 استكشاف الأخطاء

### خطأ: "OPENAI_API_KEY not configured"
**الحل**: تأكد من وجود `.env` ووضع المفتاح الصحيح

### خطأ: "Table 'chat_sessions' doesn't exist"
**الحل**: نفّذ migration SQL

### بطء في الاستجابة
**السبب**: OpenAI API يأخذ 2-5 ثواني
**الحل**: أضف مؤشر تحميل في الواجهة

### خطأ: "Cannot find module 'axios'"
**الحل**: 
```bash
npm install
```

---

## 📞 الدعم

راجع الملفات التالية للمزيد من التفاصيل:
- `docs/AI_CHAT_API.md` - توثيق API كامل
- `docs/FLUTTER_INTEGRATION_GUIDE.md` - دليل Flutter
- `services/aiService.js` - كود خدمة OpenAI
- `controllers/aiController.js` - منطق الـ endpoints

---

## 🎯 الخطوات التالية

1. ✅ **اختبر الباك إند** باستخدام Postman/curl
2. ✅ **طبّق Flutter** حسب الدليل
3. ✅ **اختبر التكامل الكامل** end-to-end
4. 📊 راقب استهلاك OpenAI من dashboard
5. 🔐 فعّل rate limiting إضافي إذا لزم
6. 📈 أضف analytics للاستخدام والتحسين

---

## ✨ الميزات المستقبلية المقترحة

- **Streaming responses**: عرض الرد بشكل تدريجي
- **Voice input/output**: دعم الصوت
- **شرح نتائج التقييم**: endpoint منفصل لشرح الدرجات
- **توصيات مخصصة**: تحسين اقتراحات التمارين بالذكاء الاصطناعي
- **تحليل الصور**: وصف صور المستخدم بشكل داعم
- **Multi-turn context**: تحسين فهم السياق عبر الجلسات

---

تم التنفيذ بنجاح! 🎉
