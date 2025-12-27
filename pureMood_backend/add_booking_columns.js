const sequelize = require('./config/db');

async function addColumnIfNotExists(columnName, columnDef) {
  try {
    // Check if column exists
    const [results] = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'puremood' 
        AND TABLE_NAME = 'bookings' 
        AND COLUMN_NAME = '${columnName}'
    `);
    
    if (results.length === 0) {
      console.log(`Adding column: ${columnName}`);
      await sequelize.query(`ALTER TABLE bookings ADD COLUMN ${columnName} ${columnDef}`);
      console.log(`✅ Added ${columnName}`);
    } else {
      console.log(`⏭️  Column ${columnName} already exists`);
    }
  } catch (err) {
    console.error(`❌ Error adding ${columnName}:`, err.message);
  }
}

async function addColumns() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected\n');

    // Add missing columns one by one
    await addColumnIfNotExists('payment_intent_id', 'VARCHAR(255) NULL');
    await addColumnIfNotExists('refund_amount', 'DECIMAL(10,2) DEFAULT 0');
    await addColumnIfNotExists('refund_reason', 'TEXT NULL');
    await addColumnIfNotExists('refunded_at', 'DATETIME NULL');
    await addColumnIfNotExists('cancelled_by', "ENUM('patient', 'specialist') NULL");
    await addColumnIfNotExists('cancelled_at', 'DATETIME NULL');
    await addColumnIfNotExists('no_show', 'BOOLEAN DEFAULT FALSE');
    
    console.log('\n✅ All columns processed successfully');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

addColumns();
