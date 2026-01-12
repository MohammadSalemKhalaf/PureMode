// 🧪 اختبار ميزة تذكير فتح التطبيق
// هذا الملف للاختبار فقط - يمكن حذفه لاحقاً

const axios = require('axios');

// إعدادات الاختبار
const BASE_URL = 'http://localhost:5000'; // أو عنوان السيرفر
const TEST_USER_TOKEN = 'YOUR_USER_TOKEN_HERE'; // ضع هنا token المستخدم للاختبار

// دالة اختبار تذكير فتح التطبيق
async function testAppStartupReminder() {
  try {
    console.log('🧪 Testing app startup reminder...');
    
    const response = await axios.post(
      `${BASE_URL}/api/user-notifications/app-startup-reminder`,
      {}, // لا نحتاج body data
      {
        headers: {
          'Authorization': `Bearer ${TEST_USER_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ App startup reminder scheduled successfully:');
    console.log(response.data);
    
    console.log('⏰ Waiting for 1 minute to receive the reminder...');
    console.log('📱 Check your device for the push notification!');
    
  } catch (error) {
    console.error('❌ Error testing app startup reminder:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

// دالة اختبار حالة خدمة التذكير
async function testReminderServiceStatus() {
  try {
    console.log('🔍 Checking reminder service status...');
    
    const response = await axios.get(
      `${BASE_URL}/api/user-notifications/mood-reminder/settings`,
      {
        headers: {
          'Authorization': `Bearer ${TEST_USER_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('📊 Reminder service status:');
    console.log(response.data);
    
  } catch (error) {
    console.error('❌ Error checking service status:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

// تشغيل الاختبارات
async function runTests() {
  console.log('🚀 Starting app startup reminder tests...\n');
  
  // اختبار حالة الخدمة أولاً
  await testReminderServiceStatus();
  
  console.log('\n' + '='.repeat(50) + '\n');
  
  // اختبار تذكير فتح التطبيق
  await testAppStartupReminder();
  
  console.log('\n🎉 Tests completed!');
  console.log('💡 Make sure to:');
  console.log('1. Replace TEST_USER_TOKEN with a valid user token');
  console.log('2. Ensure the user has FCM token registered');
  console.log('3. Check that the user hasn\'t logged mood today');
}

// تشغيل الاختبارات إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  runTests();
}

module.exports = {
  testAppStartupReminder,
  testReminderServiceStatus,
  runTests
};
