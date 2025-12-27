require('dotenv').config();
const mysql = require('mysql2/promise');

async function fixConstraints() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
  });

  try {
    console.log('✅ Connected to database');
    
    // Drop old constraint
    console.log('\n🔧 Dropping old foreign key constraint...');
    try {
      await connection.query('ALTER TABLE payments DROP FOREIGN KEY payments_ibfk_3');
      console.log('✅ Old constraint dropped');
    } catch (e) {
      console.log('⚠️  Constraint might not exist:', e.message);
    }
    
    // Add new constraint
    console.log('\n🔧 Adding new foreign key constraint...');
    try {
      await connection.query(`
        ALTER TABLE payments 
        ADD CONSTRAINT payments_specialist_fk 
        FOREIGN KEY (specialist_id) 
        REFERENCES specialists(specialist_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
      `);
      console.log('✅ New constraint added');
    } catch (e) {
      console.log('⚠️  Constraint might already exist:', e.message);
    }
    
    // Verify
    console.log('\n📋 Verifying constraints...');
    const [rows] = await connection.query(`
      SELECT 
        CONSTRAINT_NAME,
        TABLE_NAME,
        COLUMN_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE TABLE_NAME = 'payments' 
        AND TABLE_SCHEMA = 'puremood'
        AND REFERENCED_TABLE_NAME IS NOT NULL
    `);
    console.table(rows);
    
    console.log('\n✅ Done!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

fixConstraints();
