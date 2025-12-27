const dotenv = require('dotenv');
dotenv.config();

const sequelize = require('../config/db');

const simpleFix = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');

    // 1. إنشاء الشارات واحدة تلو الأخرى
    console.log('🔄 Creating badges...');
    
    const badges = [
      ['Mood Master', 'Completed 7-day mood streak'],
      ['Consistency King', 'Logged mood every day for a week'],
      ['Task Champion', 'Completed extra tasks consistently']
    ];
    
    for (const [name, description] of badges) {
      // تحقق أولاً إذا كانت الشارة موجودة
      const [existing] = await sequelize.query(
        'SELECT badge_id FROM badges WHERE name = ?',
        { replacements: [name] }
      );
      
      if (existing.length === 0) {
        await sequelize.query(
          'INSERT INTO badges (name, description) VALUES (?, ?)',
          { replacements: [name, description] }
        );
        console.log(`✅ Created badge: ${name}`);
      } else {
        console.log(`ℹ️ Badge already exists: ${name}`);
      }
    }

    // 2. تحديث التحديات مع badge_id
    console.log('🔄 Assigning badges to challenges...');
    
    const mappings = [
      ['7-Day Streak', 'Mood Master'],
      ['Daily Mood Entry', 'Consistency King'],
      ['Extra Task', 'Task Champion']
    ];
    
    for (const [challengeName, badgeName] of mappings) {
      // جلب badge_id أولاً
      const [badgeResult] = await sequelize.query(
        'SELECT badge_id FROM badges WHERE name = ?',
        { replacements: [badgeName] }
      );
      
      if (badgeResult.length > 0) {
        const badgeId = badgeResult[0].badge_id;
        
        await sequelize.query(
          'UPDATE challenges SET badge_id = ? WHERE name = ?',
          { replacements: [badgeId, challengeName] }
        );
        
        console.log(`✅ Linked ${challengeName} → ${badgeName} (ID: ${badgeId})`);
      }
    }

    // 3. عرض النتائج النهائية
    console.log('🔍 Final results:');
    
    const [results] = await sequelize.query(`
      SELECT c.name as challenge_name, b.name as badge_name 
      FROM challenges c 
      LEFT JOIN badges b ON c.badge_id = b.badge_id
    `);
    
    results.forEach(row => {
      console.log(`   - ${row.challenge_name} → ${row.badge_name || 'No badge'}`);
    });
    
    console.log('🎉 Success! System is ready for badges.');
    process.exit(0);
    
  } catch (err) {
    console.error('❌ Error:', err);
    process.exit(1);
  }
};

simpleFix();