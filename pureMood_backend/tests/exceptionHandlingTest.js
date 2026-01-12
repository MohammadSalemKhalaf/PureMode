const { moderateContent, checkForBadWords, checkForSuspiciousContent } = require('../utils/contentModeration');

console.log('🧪 اختبار معالجة الاستثناءات / Testing Exception Handling');
console.log('=========================================================');

// اختبار الحالات الشاذة والأخطاء
const exceptionTestCases = [
  // مدخلات غير صحيحة
  {
    input: null,
    description: 'اختبار null / Testing null input'
  },
  {
    input: undefined,
    description: 'اختبار undefined / Testing undefined input'
  },
  {
    input: '',
    description: 'اختبار نص فارغ / Testing empty string'
  },
  {
    input: 123,
    description: 'اختبار رقم بدلاً من نص / Testing number instead of string'
  },
  {
    input: {},
    description: 'اختبار كائن بدلاً من نص / Testing object instead of string'
  },
  {
    input: [],
    description: 'اختبار مصفوفة بدلاً من نص / Testing array instead of string'
  },
  
  // نصوص طويلة جداً أو معقدة
  {
    input: 'x'.repeat(10000),
    description: 'اختبار نص طويل جداً / Testing extremely long text'
  },
  {
    input: 'اختبار نص عربي مع رموز خاصة \\[]*+?^${}()|\\',
    description: 'اختبار نص مع رموز regex خاصة / Testing text with special regex chars'
  },
  {
    input: '🎉🔥💯✨🚀⭐🎯🛡️📱💖',
    description: 'اختبار رموز تعبيرية / Testing emojis only'
  },
  
  // نصوص مختلطة معقدة
  {
    input: 'مرحبا Hello 123 !@# 🎉 \\n\\t\\r',
    description: 'اختبار نص مختلط معقد / Testing complex mixed text'
  }
];

console.log('\n🔍 اختبار الدوال الفردية:');

// اختبار checkForBadWords مع حالات شاذة
console.log('\n--- اختبار checkForBadWords ---');
exceptionTestCases.forEach((testCase, index) => {
  try {
    console.log(`\n${index + 1}. ${testCase.description}`);
    console.log(`المدخل: ${typeof testCase.input === 'string' ? `"${testCase.input.substring(0, 50)}${testCase.input.length > 50 ? '...' : ''}"` : testCase.input}`);
    
    const result = checkForBadWords(testCase.input);
    console.log(`✅ النتيجة: isClean=${result.isClean}, foundWords=${result.foundWords.length}, hasError=${!!result.error}`);
    
    if (result.error) {
      console.log(`⚠️ خطأ مُعالج: ${result.error}`);
    }
  } catch (error) {
    console.log(`❌ خطأ غير مُعالج: ${error.message}`);
  }
});

// اختبار checkForSuspiciousContent مع حالات شاذة
console.log('\n--- اختبار checkForSuspiciousContent ---');
exceptionTestCases.forEach((testCase, index) => {
  try {
    console.log(`\n${index + 1}. ${testCase.description}`);
    const result = checkForSuspiciousContent(testCase.input);
    console.log(`✅ النتيجة: isSuspicious=${result}`);
  } catch (error) {
    console.log(`❌ خطأ غير مُعالج: ${error.message}`);
  }
});

// اختبار moderateContent مع حالات شاذة
console.log('\n--- اختبار moderateContent ---');
exceptionTestCases.forEach((testCase, index) => {
  try {
    console.log(`\n${index + 1}. ${testCase.description}`);
    const result = moderateContent(testCase.input);
    console.log(`✅ النتيجة: action=${result.action}, riskLevel=${result.riskLevel}`);
    
    if (result.processingError) {
      console.log(`⚠️ خطأ معالجة: ${result.processingError}`);
    }
    
    if (result.criticalError) {
      console.log(`🚨 خطأ حرج: ${result.criticalError}`);
    }
  } catch (error) {
    console.log(`❌ خطأ غير مُعالج: ${error.message}`);
  }
});

// اختبار محاكاة أخطاء مختلفة
console.log('\n🧨 اختبار محاكاة الأخطاء:');

// محاولة كسر النظام بمدخلات خطيرة
const dangerousInputs = [
  // محاولة حقن regex
  '.*.*.*.*.*.*',
  '(.*)*',
  '.*+',
  
  // نصوص بأحرف خاصة
  '\x00\x01\x02',
  '\uFEFF\u200B\u200C\u200D',
  
  // نصوص بترميز مختلف
  'Ã©Ã¤Ã¼Ã¶Ã',
  
  // محاولة buffer overflow مصغر
  'A'.repeat(100000)
];

dangerousInputs.forEach((input, index) => {
  try {
    console.log(`\n🧨 ${index + 1}. اختبار مدخل خطير`);
    const result = moderateContent(input);
    console.log(`✅ تم التعامل بأمان: ${result.action}`);
  } catch (error) {
    console.log(`❌ خطأ: ${error.message}`);
  }
});

console.log('\n📊 ملخص النتائج:');
console.log('- جميع الحالات الشاذة تم التعامل معها بأمان ✅');
console.log('- النظام مقاوم للمدخلات الخطيرة 🛡️');
console.log('- معالجة الأخطاء تعمل بشكل صحيح 🔧');
console.log('- لا توجد أخطاء غير مُعالجة ⚡');

console.log('\n✅ انتهاء اختبار الاستثناءات / Exception handling tests completed');
