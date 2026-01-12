const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

async function addModerationFields() {
  try {
    console.log('🔄 Adding moderation fields to community_comments table...');

    // إضافة الحقول الجديدة للمراقبة
    await sequelize.getQueryInterface().addColumn('community_comments', 'original_content', {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: 'Original content before moderation filtering'
    });

    await sequelize.getQueryInterface().addColumn('community_comments', 'moderation_status', {
      type: DataTypes.ENUM('clean', 'filtered', 'flagged', 'rejected'),
      defaultValue: 'clean',
      allowNull: false,
      comment: 'Status of content moderation'
    });

    await sequelize.getQueryInterface().addColumn('community_comments', 'risk_level', {
      type: DataTypes.ENUM('low', 'medium', 'high'),
      defaultValue: 'low',
      allowNull: false,
      comment: 'Risk level assigned by moderation system'
    });

    await sequelize.getQueryInterface().addColumn('community_comments', 'flagged_words', {
      type: DataTypes.JSON,
      allowNull: true,
      comment: 'Array of flagged words found in content'
    });

    console.log('✅ Successfully added moderation fields to community_comments table');

    // تحديث التعليقات الموجودة بقيم افتراضية
    await sequelize.query(`
      UPDATE community_comments 
      SET 
        moderation_status = 'clean',
        risk_level = 'low'
      WHERE 
        moderation_status IS NULL OR risk_level IS NULL
    `);

    console.log('✅ Updated existing comments with default moderation values');

  } catch (error) {
    console.error('❌ Error adding moderation fields:', error);
    
    // إذا كانت الحقول موجودة بالفعل، فهذا طبيعي
    if (error.message.includes('already exists') || error.message.includes('Duplicate column')) {
      console.log('ℹ️ Moderation fields already exist, skipping...');
      return;
    }
    
    throw error;
  }
}

// تشغيل المهاجرة
if (require.main === module) {
  addModerationFields()
    .then(() => {
      console.log('🎉 Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addModerationFields };
