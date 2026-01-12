const { moderateContent, checkForBadWords, checkForSuspiciousContent } = require('../utils/contentModeration');

console.log('🧪 اختبار نظام منع التعليقات السيئة / Testing Comment Moderation System');
console.log('=====================================================');

// اختبارات أساسية
const testCases = [
  // تعليقات نظيفة
  {
    text: 'هذا تعليق جميل ومفيد للجميع',
    description: 'تعليق عربي نظيف / Clean Arabic comment'
  },
  {
    text: 'This is a helpful and positive comment',
    description: 'تعليق إنجليزي نظيف / Clean English comment'
  },
  
  // تعليقات تحتاج فلترة
  {
    text: 'أنت غبي ولا تفهم شيء',
    description: 'تعليق عربي يحتاج فلترة / Arabic comment needing filtering'
  },
  {
    text: 'You are stupid and don\'t understand anything',
    description: 'تعليق إنجليزي يحتاج فلترة / English comment needing filtering'
  },
  
  // تعليقات سيئة جداً
  {
    text: 'أنت غبي وأحمق ومعتوه يا كلب',
    description: 'تعليق عربي سيء جداً / Very bad Arabic comment'
  },
  {
    text: 'You are stupid idiot moron shut up',
    description: 'تعليق إنجليزي سيء جداً / Very bad English comment'
  },
  
  // تعليقات مشبوهة
  {
    text: 'HELLOOOOOOO EVERYONE!!!!!',
    description: 'تعليق مشبوه - تكرار وصراخ / Suspicious comment - repetition and shouting'
  },
  {
    text: 'اتصل بي على 01234567890',
    description: 'تعليق يحتوي أرقام / Comment with phone numbers'
  }
];

// تشغيل الاختبارات
testCases.forEach((testCase, index) => {
  console.log(`\n📝 الاختبار ${index + 1}: ${testCase.description}`);
  console.log(`النص الأصلي: "${testCase.text}"`);
  
  const moderation = moderateContent(testCase.text);
  
  console.log(`✅ النتيجة: ${moderation.action} (مستوى الخطر: ${moderation.riskLevel})`);
  
  if (!moderation.isClean) {
    console.log(`🔍 الكلمات المكتشفة: ${moderation.foundWords.join(', ')}`);
    console.log(`📝 النص بعد الفلترة: "${moderation.cleanText}"`);
  }
  
  console.log(`📋 السبب: ${moderation.reason}`);
  console.log('---');
});

// اختبارات خاصة بوظائف محددة
console.log('\n🔍 اختبار فحص الكلمات السيئة المنفرد:');
const badWordTest = checkForBadWords('هذا النص يحتوي كلمة غبي');
console.log('الكلمات المكتشفة:', badWordTest.foundWords);
console.log('النص المنظف:', badWordTest.cleanText);

console.log('\n🚨 اختبار فحص المحتوى المشبوه:');
const suspiciousTests = [
  'HELLOOOOO WORLD!!!!',
  'Normal text here',
  'اتصل على 01234567890123'
];

suspiciousTests.forEach(text => {
  const isSuspicious = checkForSuspiciousContent(text);
  console.log(`"${text}" - مشبوه: ${isSuspicious ? 'نعم' : 'لا'}`);
});

console.log('\n✅ انتهاء الاختبارات / Tests completed');
console.log('\n📊 ملخص النظام / System Summary:');
console.log('- يمنع التعليقات التي تحتوي على كلمات سيئة كثيرة');
console.log('- يفلتر الكلمات السيئة القليلة');
console.log('- يكتشف المحتوى المشبوه');
console.log('- يدعم اللغتين العربية والإنجليزية');
console.log('- Blocks comments with many bad words');
console.log('- Filters few bad words');
console.log('- Detects suspicious content');
console.log('- Supports Arabic and English languages');
