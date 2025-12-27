const db = require('./config/db');

async function addTestSpecialists() {
  try {
    console.log('🔄 Adding test specialists...');
    
    // 1. Add users (استخدم hash بدل password)
    await db.query(`
      INSERT INTO users (name, email, hash, age, gender, status, created_at)
      VALUES 
        ('Dr. Ahmad Khalil', 'ahmad.specialist@puremood.com', '$2a$10$dummyHashPassword123456789012345678901234567890', 38, 'male', 'accepted', NOW()),
        ('Dr. Sara Mohammed', 'sara.specialist@puremood.com', '$2a$10$dummyHashPassword123456789012345678901234567890', 35, 'female', 'accepted', NOW())
      ON DUPLICATE KEY UPDATE name=name
    `);
    
    // 2. Get user IDs
    const [ahmadUser] = await db.query(`
      SELECT user_id FROM users WHERE email = 'ahmad.specialist@puremood.com'
    `);
    const [saraUser] = await db.query(`
      SELECT user_id FROM users WHERE email = 'sara.specialist@puremood.com'
    `);
    
    const ahmadId = ahmadUser[0]?.user_id;
    const saraId = saraUser[0]?.user_id;
    
    if (!ahmadId || !saraId) {
      console.error('❌ Failed to get user IDs');
      return;
    }
    
    console.log(`✅ Users created: Ahmad=${ahmadId}, Sara=${saraId}`);
    
    // 3. Add specialists
    await db.query(`
      INSERT INTO specialists (
        user_id, specialization, license_number, years_of_experience,
        bio, education, languages, session_price, rating, total_reviews,
        is_verified, is_available, created_at
      ) VALUES 
      (?, 'Depression & Anxiety', 'PSY-001', 10,
       'خبير في علاج الاكتئاب والقلق باستخدام العلاج المعرفي السلوكي',
       'PhD in Clinical Psychology - Jordan University',
       '["Arabic", "English"]', 50.00, 4.8, 25, TRUE, TRUE, NOW()),
      (?, 'Stress & Trauma', 'PSY-002', 8,
       'متخصصة في علاج الصدمات والتوتر النفسي',
       'PhD in Clinical Psychology - Cairo University',
       '["Arabic", "English", "French"]', 60.00, 4.9, 18, TRUE, TRUE, NOW())
      ON DUPLICATE KEY UPDATE specialization=specialization
    `, { replacements: [ahmadId, saraId] });
    
    console.log('✅ Specialists added successfully!');
    
    // 4. Verify
    const [specialists] = await db.query(`
      SELECT s.specialist_id, u.name, s.specialization, s.rating
      FROM specialists s
      JOIN users u ON s.user_id = u.user_id
      WHERE s.is_verified = TRUE
    `);
    
    console.log('\n📋 Current specialists:');
    specialists.forEach(sp => {
      console.log(`  - ${sp.name} (${sp.specialization}) - Rating: ${sp.rating}⭐`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addTestSpecialists();
