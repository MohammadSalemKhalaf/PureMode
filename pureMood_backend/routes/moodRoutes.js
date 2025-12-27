const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const sequelize = require('../config/db');
const { generateRecommendations } = require('../controllers/recommendationController');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const multer = require('multer');

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const HUGGINGFACE_API_TOKEN = process.env.HUGGINGFACE_API_TOKEN;

// إعداد رفع صور المزاج
const imageUploadDir = path.join(__dirname, '..', 'uploads', 'mood_images');
const imageStorage = multer({ dest: imageUploadDir });

async function analyzeImageMoodWithPython(imageAbsolutePath) {
  try {
    await fs.promises.mkdir(imageUploadDir, { recursive: true });

    const formData = new FormData();
    const fileStream = fs.createReadStream(imageAbsolutePath);
    formData.append('file', fileStream);

    const response = await axios.post('http://localhost:8001/analyze_image', formData, {
      headers: {
        ...formData.getHeaders(),
      },
      maxBodyLength: Infinity,
    });

    const emotion = response.data?.emotion || 'neutral';

    let emoji = '😐';
    if (emotion === 'happy') {
      emoji = '😄';
    } else if (emotion === 'sad') {
      emoji = '😢';
    }

    return { emotion, emoji, rawEmotion: response.data?.raw_emotion || emotion };
  } catch (error) {
    console.error('خطأ أثناء استدعاء خدمة تحليل صورة الوجه:', error.message);
    return { emotion: 'neutral', emoji: '😐', rawEmotion: null };
  }
}

// 🎧 تحويل الصوت إلى نص عربي باستخدام Whisper (OpenAI)
async function transcribeAudioToText(audioAbsolutePath) {
  if (!OPENAI_API_KEY) {
    console.log('ℹ️  OPENAI_API_KEY غير موجود في .env، سيتم تخطي تفريغ الصوت');
    return null;
  }

  try {
    const fileStream = fs.createReadStream(audioAbsolutePath);

    const formData = new FormData();
    formData.append('file', fileStream);
    formData.append('model', 'whisper-1');
    formData.append('language', 'ar');

    const response = await axios.post('https://api.openai.com/v1/audio/transcriptions', formData, {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        ...formData.getHeaders(),
      },
      maxBodyLength: Infinity,
    });

    const text = response.data.text;
    console.log('�️ Transcribed Arabic text:', text);
    return text || null;
  } catch (err) {
    console.error('⚠️  فشل تفريغ الصوت إلى نص:', err.message);
    return null;
  }
}

// 😊 تحليل النص العربي لاستخراج المزاج (إيجابي/سلبي/محايد) وتحويله لإيموجي
// نسخة محلية بسيطة بدون استدعاء أي API خارجي، تعتمد على كلمات مفتاحية
async function analyzeArabicTextMood(text) {
  if (!text || typeof text !== 'string') {
    return null;
  }

  const normalized = text
    .toLowerCase()
    .replace(/[\u064B-\u0652]/g, '') // إزالة التشكيل
    .replace(/إ|أ|آ/g, 'ا'); // توحيد الألف

  const sadWords = [
    // حزن عام
    'حزين', 'حزينه', 'حزينة', 'زعلان', 'زعلانه', 'زعلانة',
    'مكسور', 'مكسوره', 'مكسورة', 'محبط', 'محبطه', 'محبطة',
    'مهموم', 'مهمومة', 'مدايق', 'مضايق', 'متضايق', 'متضايقة',
    'مخنوق', 'مخنوقة', 'مقهور', 'مقهورة', 'مكتئب', 'مكتئبه', 'مكتئبة', 'اكتئاب',

    // تعب وضغط نفسي
    'تعبان', 'تعبانه', 'تعبانة', 'تعب', 'مرهق', 'مرهقة',
    'مضغوط', 'مضغوطة', 'ضغط نفسي', 'ضغط', 'زهقان', 'زهقانه', 'زهقانة',
    'مليت', 'طفشان', 'طفشانة',

    // قلق وخوف
    'خايف', 'خايفة', 'قلق', 'قلقانه', 'قلقانة', 'توتر', 'متوتر', 'متوترة',

    // تعابير الألم الجسدي
    'وجع', 'يوجع', 'بوجع', 'راسي بوجع', 'راس بيوجع', 'صداع', 'مصدع',
    'مريضة', 'مريض', 'تعب جسمي', 'تعبانة جسديا', 'تعبانة جسديًا',

    // تعبيرات يومية سلبية
    'ما الي نفس', 'ما إلي نفس', 'مالي خلق', 'مو قادرة', 'مو قادر',
    'كرهت كل شيء', 'مو طايقة حدا'
  ];

  const happyWords = [
    // سعادة وفرح
    'سعيد', 'سعيدة', 'مبسوط', 'مبسوطة', 'مبسوطه',
    'فرحان', 'فرحانه', 'فرحانة', 'فرح', 'مسرور', 'مسرورة',

    // راحة وطمأنينة
    'مرتاح', 'مرتاحه', 'مرتاحه', 'مرتاحين', 'مطمئن', 'مطمئنة', 'مرتاح نفسيا',

    // امتنان وتقدير
    'ممتن', 'ممتنة', 'شاكر', 'شاكرة', 'شاكره', 'شاكر لله',

    // تفاؤل وحماس
    'متحمس', 'متحمسة', 'متحمسه', 'متفائل', 'متفائلة', 'متفائله',
    'راضي', 'راضية', 'راض',
  ];

  const containsFromList = (words) =>
    words.some((w) => normalized.includes(w));

  let emoji = '😐';
  let moodLabel = 'Neutral';
  let rawLabel = 'NEU';

  if (containsFromList(sadWords)) {
    emoji = '😢';
    moodLabel = 'Sad';
    rawLabel = 'NEG';
  } else if (containsFromList(happyWords)) {
    emoji = '😊';
    moodLabel = 'Happy';
    rawLabel = 'POS';
  }

  console.log('🧠 Local Arabic text mood analysis:', { rawLabel, emoji, moodLabel, text });

  return {
    emoji,
    moodLabel,
    rawLabel,
    score: 1.0,
  };
}

// �🔥 GET /api/moods - جلب كل مزاجات المستخدم
router.get('/', verifyToken, async (req, res) => {
  try {
    console.log('📊 جلب مزاجات للمستخدم:', req.user.user_id);
    
    // جرب أسماء جداول مختلفة
    const tableNames = ['mood_entries', 'moods'];
    
    for (let tableName of tableNames) {
      try {
        const [results] = await sequelize.query(
          `SELECT * FROM ${tableName} WHERE user_id = ? ORDER BY created_at DESC`,
          { replacements: [req.user.user_id] }
        );
        
        console.log(`✅ تم جلب ${results.length} تسجيل مزاج من جدول: ${tableName}`);
        return res.json(results);
      } catch (e) {
        console.log(`❌ جدول ${tableName} غير موجود: ${e.message}`);
      }
    }
    
    // إذا لم توجد أي جداول، أرجع مصفوفة فارغة
    console.log('⚠️ لا توجد جداول مزاجات، إرجاع بيانات فارغة');
    res.json([]);
    
  } catch (err) {
    console.error('❌ خطأ في جلب المزاجات:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔥 POST /api/moods/add - إضافة مزاج جديد
router.post('/add', verifyToken, async (req, res) => {
  try {
    const { mood_emoji, note_text, note_audio } = req.body;
    console.log('➕ إضافة مزاج جديد:', { mood_emoji, note_text });

    // ✅ حفظ ملف الصوت على القرص (إن وجد) وتخزين المسار فقط
    let audioPath = null;
    if (note_audio) {
      try {
        const uploadsDir = path.join(__dirname, '..', 'uploads', 'mood_audio');
        await fs.promises.mkdir(uploadsDir, { recursive: true });

        const filename = `user_${req.user.user_id}_${Date.now()}.m4a`;
        const filePath = path.join(uploadsDir, filename);

        const base64Data = note_audio.split(',').pop();
        const audioBuffer = Buffer.from(base64Data, 'base64');
        await fs.promises.writeFile(filePath, audioBuffer);

        audioPath = `/uploads/mood_audio/${filename}`;
        console.log('🎙️ تم حفظ ملف الصوت في:', audioPath);
      } catch (fileErr) {
        console.error('⚠️ خطأ في حفظ ملف الصوت، سيتم المتابعة بدون صوت:', fileErr.message);
      }
    }

    // 🎯 تحديد الإيموجي الفعّال: إمّا من المستخدم أو من AI اعتماداً على النص المكتوب
    let effectiveEmoji = (mood_emoji && mood_emoji.trim() !== '') ? mood_emoji : null;
    let aiMoodInfo = null;

    // أولاً: إذا لا يوجد إيموجي لكن يوجد نص مكتوب، نحلّل النص مباشرة
    if (!effectiveEmoji && note_text && note_text.trim() !== '') {
      try {
        aiMoodInfo = await analyzeArabicTextMood(note_text);
        if (aiMoodInfo && aiMoodInfo.emoji) {
          effectiveEmoji = aiMoodInfo.emoji;
        }
      } catch (aiErr) {
        console.error('⚠️  خطأ أثناء تحليل المزاج من النص:', aiErr.message);
      }
    }

    // في حال لم يتوفر أي إيموجي (لا من المستخدم ولا من AI)، نضع إيموجي محايد افتراضي
    if (!effectiveEmoji) {
      effectiveEmoji = '😐';
    }

    // نستخدم فقط جدول mood_entries لأنه الجدول الفعّال
    const tableName = 'mood_entries';
    try {
      const [result] = await sequelize.query(
        `INSERT INTO ${tableName} (user_id, mood_emoji, note_text, note_audio, created_at) 
         VALUES (?, ?, ?, ?, NOW())`,
        { replacements: [req.user.user_id, effectiveEmoji, note_text, audioPath,] }
      );

      console.log(`✅ تم إضافة مزاج جديد في جدول: ${tableName}، ID: ${result.insertId}`);

      // 🎯 توليد توصيات تلقائياً بناءً على المزاج
      let recommendations = [];
      try {
        recommendations = await generateRecommendations(
          req.user.user_id,
          effectiveEmoji,
          result.insertId
        );
        console.log(`✅ تم توليد ${recommendations.length} توصية للمزاج: ${effectiveEmoji}`);
      } catch (recError) {
        console.error('⚠️ خطأ في توليد التوصيات:', recError);
        // لا نوقف العملية إذا فشل توليد التوصيات
      }

      return res.json({
        message: "Mood saved successfully!",
        mood_id: result.insertId,
        recommendations_count: recommendations.length,
        recommendations: recommendations,
        note_audio_path: audioPath,
        effective_mood_emoji: effectiveEmoji,
        ai_mood_info: aiMoodInfo,
      });
    } catch (e) {
      console.log(`❌ فشل الإدراج في جدول ${tableName}: ${e.message}`);
      throw new Error('لم يتمكن من حفظ المزاج في قاعدة البيانات');
    }
  } catch (err) {
    console.error('❌ خطأ في حفظ المزاج:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔥 GET /api/moods/user/me - جلب مزاجات المستخدم الحالي
router.get('/user/me', verifyToken, async (req, res) => {
  try {
    console.log('📊 جلب مزاجات للمستخدم الحالي:', req.user.user_id);
    
    // نفس منطق الـ GET الأساسي
    const tableNames = ['mood_entries', 'moods'];
    
    for (let tableName of tableNames) {
      try {
        const [results] = await sequelize.query(
          `SELECT * FROM ${tableName} WHERE user_id = ? ORDER BY created_at DESC`,
          { replacements: [req.user.user_id] }
        );
        
        console.log(`✅ تم جلب ${results.length} تسجيل مزاج من جدول: ${tableName}`);
        return res.json(results);
      } catch (e) {
        console.log(`❌ جدول ${tableName} غير موجود: ${e.message}`);
      }
    }
    
    res.json([]);
    
  } catch (err) {
    console.error('❌ خطأ في جلب المزاجات:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔥 DELETE /api/moods/:mood_id - حذف مزاج
router.delete('/:mood_id', verifyToken, async (req, res) => {
  try {
    const { mood_id } = req.params;
    console.log('🗑️ حذف مزاج:', mood_id);
    
    // جرب حذف من الجداول المختلفة
    const tableNames = ['mood_entries', 'moods'];
    
    for (let tableName of tableNames) {
      try {
        const [result] = await sequelize.query(
          `DELETE FROM ${tableName} WHERE mood_id = ? AND user_id = ?`,
          { replacements: [mood_id, req.user.user_id] }
        );
        
        if (result.affectedRows > 0) {
          console.log(`✅ تم حذف المزاج من جدول: ${tableName}`);
          return res.json({ message: "Mood deleted successfully!" });
        }
      } catch (e) {
        console.log(`❌ فشل الحذف من جدول ${tableName}: ${e.message}`);
      }
    }
    
    res.status(404).json({ message: "Mood not found" });
    
  } catch (err) {
  }
});

// 🔍 POST /api/moods/analyze-image - تحليل مزاج من صورة وجه
router.post('/analyze-image', verifyToken, imageStorage.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Image file is required (field name: file)' });
    }

    const imagePath = req.file.path;

    const result = await analyzeImageMoodWithPython(imagePath);

    fs.unlink(imagePath, (err) => {
      if (err) {
        console.error('خطأ أثناء حذف ملف الصورة المؤقت:', err.message);
      }
    });

    return res.json(result);
  } catch (err) {
    console.error('خطأ أثناء تحليل صورة المزاج:', err);
    return res.status(500).json({ emotion: 'neutral', emoji: '😐', error: err.message });
  }
});

module.exports = router;