// 🧪 Script لإنشاء إشعار تجريبي

const sequelize = require('./config/db');

async function createTestNotification() {
  try {
    // الاتصال بقاعدة البيانات
    await sequelize.authenticate();
    console.log('✅ Connected to database');

    // جلب أول admin
    const [admins] = await sequelize.query(
      "SELECT user_id, name, email FROM users WHERE role = 'admin' LIMIT 1"
    );

    if (admins.length === 0) {
      console.log('❌ No admin found!');
      process.exit(1);
    }

    const admin = admins[0];
    console.log(`👤 Found admin: ${admin.name} (${admin.email})`);

    // إنشاء إشعار تجريبي
    await sequelize.query(
      `INSERT INTO notifications (admin_id, type, title, message, data, is_read, created_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      {
        replacements: [
          admin.user_id,
          'new_user_pending',
          'طلب تسجيل أخصائي جديد - اختبار',
          'هذا إشعار تجريبي للتأكد من عمل النظام',
          JSON.stringify({ test: true, user_id: 999 }),
          false
        ]
      }
    );

    console.log('✅ Test notification created successfully!');
    console.log('🔔 Check your app now - you should see 1 notification');

    // عرض الإشعارات
    const [notifications] = await sequelize.query(
      `SELECT notification_id, title, message, is_read, created_at 
       FROM notifications 
       WHERE admin_id = ? 
       ORDER BY created_at DESC 
       LIMIT 5`,
      { replacements: [admin.user_id] }
    );

    console.log('\n📋 Recent notifications:');
    notifications.forEach(n => {
      console.log(`- [${n.is_read ? '✓' : '○'}] ${n.title} (${n.created_at})`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
}

createTestNotification();
