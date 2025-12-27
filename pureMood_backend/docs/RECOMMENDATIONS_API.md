# 🎯 نظام التوصيات بناءً على المزاج

## نظرة عامة
تم إضافة نظام توصيات ذكي يقدم اقتراحات مخصصة للمستخدم بناءً على مزاجه الحالي. عندما يدخل المستخدم مزاجه، يحصل تلقائياً على توصيات مناسبة لمساعدته.

---

## 📋 المتطلبات

### 1. إنشاء جدول التوصيات في قاعدة البيانات
قم بتنفيذ SQL Script التالي:
```bash
mysql -u your_username -p your_database < scripts/createRecommendationsTable.sql
```

أو يمكنك تنفيذه مباشرة:
```sql
CREATE TABLE IF NOT EXISTS recommendations (
  recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  mood_id INT NULL,
  mood_emoji VARCHAR(10) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category ENUM('activity', 'music', 'exercise', 'meditation', 'food', 'social', 'reading', 'breathing') NOT NULL DEFAULT 'activity',
  icon VARCHAR(50) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (mood_id) REFERENCES mood_entries(mood_id) ON DELETE CASCADE
);
```

---

## 🚀 API Endpoints

### 1. إضافة مزاج (مع توليد توصيات تلقائي)
**POST** `/api/moods/add`

**Headers:**
```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

**Body:**
```json
{
  "mood_emoji": "😊",
  "note_text": "أشعر بسعادة اليوم",
  "note_audio": null
}
```

**Response:**
```json
{
  "message": "Mood saved successfully!",
  "mood_id": 123,
  "recommendations_count": 4,
  "recommendations": [
    {
      "recommendation_id": 456,
      "user_id": 1,
      "mood_id": 123,
      "mood_emoji": "😊",
      "title": "اكتب ما يجعلك سعيداً",
      "description": "سجّل اللحظات الجميلة في مذكرتك اليومية",
      "category": "activity",
      "icon": "📝",
      "created_at": "2024-01-01T12:00:00.000Z"
    }
  ]
}
```

---

### 2. جلب توصيات المستخدم
**GET** `/api/recommendations`

**Headers:**
```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

**Query Parameters (اختياري):**
- `mood_emoji`: فلترة التوصيات حسب مزاج معين (مثال: `?mood_emoji=😊`)
- `limit`: عدد التوصيات المطلوبة (افتراضي: 10)

**مثال:**
```
GET /api/recommendations?mood_emoji=😊&limit=5
```

**Response:**
```json
{
  "message": "Recommendations fetched successfully",
  "count": 5,
  "recommendations": [...]
}
```

---

### 3. جلب توصيات لمزاج معين (بدون حفظ)
**GET** `/api/recommendations/mood/:mood_emoji`

**مثال:**
```
GET /api/recommendations/mood/😢
```

**Response:**
```json
{
  "message": "Recommendations generated successfully",
  "mood": "😢",
  "count": 5,
  "recommendations": [
    {
      "title": "تنفس بعمق",
      "description": "خذ 5 أنفاس عميقة بطيئة لتهدئة نفسك",
      "category": "breathing",
      "icon": "🌬️"
    }
  ]
}
```

---

### 4. حذف توصية معينة
**DELETE** `/api/recommendations/:recommendation_id`

**Headers:**
```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

**Response:**
```json
{
  "message": "Recommendation deleted successfully"
}
```

---

### 5. حذف كل التوصيات للمستخدم
**DELETE** `/api/recommendations`

**Headers:**
```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

**Response:**
```json
{
  "message": "All recommendations cleared successfully",
  "deletedCount": 25
}
```

---

## 😊 المزاجات المدعومة والتوصيات

### 1. مزاج سعيد 😊
- اكتب ما يجعلك سعيداً 📝
- شارك السعادة 💬
- استمتع بالموسيقى 🎵
- تمرين خفيف 🚶

### 2. مزاج حزين 😢
- تنفس بعمق 🌬️
- اكتب مشاعرك ✍️
- استمع لموسيقى هادئة 🎼
- تواصل مع أحبائك 🤗
- مشروب دافئ ☕

### 3. مزاج قلق 😰
- تأمل لمدة 5 دقائق 🧘
- تمارين التنفس 💨
- اكتب مخاوفك 📋
- مشي سريع 🏃
- موسيقى مهدئة 🌧️

### 4. مزاج غاضب 😠
- توقف وتنفس 🛑
- تمرين رياضي مكثف 💪
- اكتب رسالة لا ترسلها 💌
- موسيقى هادئة 🎻
- استحم بماء بارد 🚿

### 5. مزاج متعب 😫
- خذ قيلولة قصيرة 😴
- تناول وجبة خفيفة صحية 🥗
- تمدد بسيط 🤸
- موسيقى منعشة 🎶
- اشرب ماء 💧

### 6. مزاج محايد 😐
- حدد هدف صغير 🎯
- استكشف هواية جديدة 🎨
- تمشى في الطبيعة 🌳
- اقرأ شيء ملهم 📚
- استمع لبودكاست 🎙️

### 7. مزاج متحمس 🤗
- ابدأ مشروع جديد 🚀
- شارك حماسك ✨
- تمرين طاقة عالية 🔥
- تعلم مهارة جديدة 🎓
- موسيقى محفزة 🎸

### 8. مزاج وحيد 🥺
- اتصل بصديق 📞
- انضم لمجتمع أونلاين 👥
- تطوع 🤝
- اذهب لمكان عام ☕
- اكتب رسالة امتنان 💝

---

## 🎨 أنواع التوصيات (Categories)

- `activity`: نشاطات عامة
- `music`: موسيقى
- `exercise`: تمارين رياضية
- `meditation`: تأمل واسترخاء
- `food`: طعام وشراب
- `social`: تواصل اجتماعي
- `reading`: قراءة وتعلم
- `breathing`: تمارين تنفس

---

## 📱 أمثلة على الاستخدام

### مثال 1: Flutter/Dart
```dart
// إضافة مزاج مع الحصول على توصيات
Future<void> addMoodWithRecommendations(String moodEmoji, String noteText) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/moods/add'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'mood_emoji': moodEmoji,
      'note_text': noteText,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Recommendations: ${data['recommendations']}');
  }
}

// جلب التوصيات
Future<List<Recommendation>> getRecommendations({String? moodEmoji}) async {
  String url = '$baseUrl/api/recommendations';
  if (moodEmoji != null) {
    url += '?mood_emoji=$moodEmoji';
  }
  
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['recommendations'] as List)
        .map((rec) => Recommendation.fromJson(rec))
        .toList();
  }
  return [];
}
```

### مثال 2: JavaScript/React
```javascript
// إضافة مزاج مع الحصول على توصيات
const addMoodWithRecommendations = async (moodEmoji, noteText) => {
  const response = await fetch(`${API_URL}/api/moods/add`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      mood_emoji: moodEmoji,
      note_text: noteText,
    }),
  });
  
  const data = await response.json();
  console.log('Recommendations:', data.recommendations);
  return data;
};

// جلب التوصيات
const getRecommendations = async (moodEmoji = null) => {
  let url = `${API_URL}/api/recommendations`;
  if (moodEmoji) {
    url += `?mood_emoji=${moodEmoji}`;
  }
  
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });
  
  return await response.json();
};
```

---

## 🔧 ملاحظات تقنية

1. **التوصيات التلقائية**: عند إضافة مزاج جديد عبر `/api/moods/add`، يتم توليد التوصيات تلقائياً وإرجاعها في الاستجابة.

2. **مزاجات غير معروفة**: إذا تم إدخال مزاج غير مدرج في القائمة، سيتم إعطاء توصيات افتراضية عامة.

3. **الأداء**: تم إضافة indexes على `user_id`, `mood_emoji`, و `created_at` لتحسين الأداء.

4. **العلاقات**: جدول التوصيات مرتبط بـ `users` و `mood_entries` مع `ON DELETE CASCADE`.

5. **الأمان**: جميع endpoints محمية بـ JWT authentication عبر `verifyToken` middleware.

---

## 🎉 نصائح للتطوير

1. **تخصيص التوصيات**: يمكنك إضافة المزيد من التوصيات في `MOOD_RECOMMENDATIONS` في `recommendationController.js`.

2. **إضافة مزاجات جديدة**: أضف مزاجات جديدة في object `MOOD_RECOMMENDATIONS`.

3. **تحليل البيانات**: يمكنك استخدام جدول `recommendations` لتحليل أي التوصيات الأكثر فعالية.

4. **AI Integration**: يمكن دمج AI لتوليد توصيات أكثر تخصيصاً بناءً على تاريخ المستخدم.

---

## 🐛 استكشاف الأخطاء

### المشكلة: لا تظهر التوصيات
**الحل:**
- تأكد من تنفيذ SQL Script لإنشاء جدول `recommendations`
- تحقق من أن الـ JWT token صحيح
- راجع logs الباك إند

### المشكلة: خطأ في الـ Foreign Key
**الحل:**
- تأكد من وجود جدول `users` و `mood_entries`
- تحقق من أن الـ user_id و mood_id موجودان

---

## 📞 الدعم

إذا واجهت أي مشاكل أو لديك اقتراحات لتحسين النظام، لا تتردد في التواصل!

تم بناء النظام بحب 💚 لمساعدة المستخدمين على تحسين صحتهم النفسية 🌿
