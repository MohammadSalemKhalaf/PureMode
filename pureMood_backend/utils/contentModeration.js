const badWordsArabic = [
  // كلمات سيئة عربية
  'غبي', 'أحمق', 'حيوان', 'كلب', 'خنزير', 'حمار', 'معتوه', 'مجنون',
  'لعنة', 'تبا', 'بلاء', 'قذر', 'وسخ', 'نذل', 'خسيس', 'حقير',
  'سافل', 'منحط', 'وضيع', 'رذيل', 'فاسد', 'منحرف', 'شيطان',
  'ابن كلب', 'ابن حرام', 'كس أمك', 'يا كلب', 'يا حيوان',
  'أخرس', 'اسكت', 'امشي', 'اتفه', 'يا غبي', 'يا أحمق'
];

const badWordsEnglish = [
  // English bad words
  'stupid', 'stubid', 'stuped', 'stupied', 'stupidd',
  'idiot', 'fool', 'moron', 'dumb', 'crazy', 'insane',
  'damn', 'hell', 'crap', 'shit', 'fuck', 'bitch', 'asshole',
  'bastard', 'jerk', 'loser', 'freak', 'weirdo', 'creep',
  'shut up', 'go away', 'get lost', 'you suck', 'hate you',
  'kill yourself', 'die', 'death', 'murder', 'violence'
];

// قائمة الكلمات المحظورة الكاملة
const allBadWords = [...badWordsArabic, ...badWordsEnglish];

/**
 * فحص النص للكلمات السيئة
 * @param {string} text - النص المراد فحصه
 * @returns {Object} - نتيجة الفحص
 */
function checkForBadWords(text) {
  try {
    if (!text || typeof text !== 'string') {
      return { isClean: true, foundWords: [], cleanText: text };
    }

    const normalizedText = text.toLowerCase().trim();
    const normalizedAlpha = normalizedText.replace(/[^a-z0-9\u0600-\u06FF]+/g, ' ');
    const foundWords = [];
    let cleanText = text;

    // فحص كل كلمة سيئة
    for (const badWord of allBadWords) {
      try {
        const normalizedBadWord = badWord.toLowerCase();
        
        // للكلمات العربية، نستخدم بحث بسيط بدون حدود كلمات لأن العربية لها خصائص مختلفة
        const isArabicWord = /[\u0600-\u06FF]/.test(badWord);
        
        let wordRegex;
        if (isArabicWord) {
          // بحث مرن للكلمات العربية
          wordRegex = new RegExp(escapeRegExp(normalizedBadWord), 'gi');
        } else {
          // بحث بحدود الكلمات للكلمات الإنجليزية
          wordRegex = new RegExp(`\\b${escapeRegExp(normalizedBadWord)}\\b`, 'gi');
        }
        
        const wordRegexAlt = new RegExp(wordRegex.source, 'gi');
        if (wordRegex.test(normalizedText) || wordRegexAlt.test(normalizedAlpha)) {
          foundWords.push(badWord);
          // استبدال الكلمة السيئة بنجوم
          cleanText = cleanText.replace(wordRegex, '*'.repeat(badWord.length));
        }
      } catch (regexError) {
        console.error(`Error processing bad word "${badWord}":`, regexError);
        // في حالة خطأ في regex، نتجاهل هذه الكلمة ونكمل
        continue;
      }
    }

    return {
      isClean: foundWords.length === 0,
      foundWords: foundWords,
      cleanText: cleanText
    };
  } catch (error) {
    console.error('Error in checkForBadWords:', error);
    // في حالة خطأ عام، نعتبر النص نظيف لتجنب منع المحتوى الصحيح
    return { 
      isClean: true, 
      foundWords: [], 
      cleanText: text,
      error: 'Processing error occurred'
    };
  }
}

/**
 * فحص النص للكلمات المشبوهة (كلمات قد تكون سيئة)
 * @param {string} text - النص المراد فحصه
 * @returns {boolean} - هل النص مشبوه
 */
function checkForSuspiciousContent(text) {
  try {
    if (!text || typeof text !== 'string') {
      return false;
    }

    const suspiciousPatterns = [
      // أنماط مشبوهة
      /(.)\1{4,}/g, // تكرار نفس الحرف أكثر من 4 مرات
      /[!@#$%^&*()]{5,}/g, // رموز خاصة كثيرة
      /\b[A-Z]{10,}\b/g, // كلمات كبيرة بأحرف كبيرة
      /\b\d{10,}\b/g // أرقام طويلة (قد تكون أرقام هواتف أو معلومات شخصية)
    ];

    return suspiciousPatterns.some(pattern => {
      try {
        return pattern.test(text);
      } catch (patternError) {
        console.error('Error testing suspicious pattern:', patternError);
        return false;
      }
    });
  } catch (error) {
    console.error('Error in checkForSuspiciousContent:', error);
    return false;
  }
}

/**
 * تقييم مستوى الخطورة للتعليق
 * @param {string} text - النص المراد تقييمه
 * @returns {Object} - مستوى الخطورة والإجراءات المقترحة
 */
function moderateContent(text) {
  try {
    // التحقق من صحة المدخلات
    if (!text || typeof text !== 'string') {
      return {
        riskLevel: 'low',
        action: 'approve',
        reason: '',
        isClean: true,
        foundWords: [],
        cleanText: text || '',
        originalText: text || ''
      };
    }

    const badWordsCheck = checkForBadWords(text);
    const isSuspicious = checkForSuspiciousContent(text);
    
    let riskLevel = 'low';
    let action = 'approve';
    let reason = '';

    // التحقق من وجود أخطاء في فحص الكلمات السيئة
    if (badWordsCheck.error) {
      console.warn('Error occurred during bad words check, proceeding with caution');
      riskLevel = 'medium';
      action = 'review';
      reason = 'خطأ في معالجة المحتوى، يحتاج مراجعة / Content processing error, needs review';
    } else if (!badWordsCheck.isClean) {
      if (badWordsCheck.foundWords.length >= 3) {
        riskLevel = 'high';
        action = 'reject';
        reason = 'المحتوى يحتوي على كلمات سيئة متعددة / Content contains multiple inappropriate words';
      } else {
        riskLevel = 'medium';
        action = 'filter';
        reason = 'المحتوى يحتوي على كلمات غير مناسبة / Content contains inappropriate words';
      }
    }

    if (isSuspicious && riskLevel === 'low') {
      riskLevel = 'medium';
      action = 'review';
      reason = 'المحتوى مشبوه ويحتاج مراجعة / Content is suspicious and needs review';
    }

    return {
      riskLevel,
      action, // approve, filter, review, reject
      reason,
      isClean: badWordsCheck.isClean,
      foundWords: badWordsCheck.foundWords || [],
      cleanText: badWordsCheck.cleanText || text,
      originalText: text,
      processingError: badWordsCheck.error || false
    };
  } catch (error) {
    console.error('Critical error in moderateContent:', error);
    // في حالة خطأ حرج، نتعامل بحذر ونطلب مراجعة يدوية
    return {
      riskLevel: 'high',
      action: 'review',
      reason: 'خطأ حرج في معالجة المحتوى / Critical content processing error',
      isClean: false,
      foundWords: [],
      cleanText: text,
      originalText: text,
      criticalError: true
    };
  }
}

/**
 * escape RegExp special characters
 * @param {string} string 
 * @returns {string}
 */
function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = {
  checkForBadWords,
  checkForSuspiciousContent,
  moderateContent,
  badWordsArabic,
  badWordsEnglish,
  allBadWords
};
