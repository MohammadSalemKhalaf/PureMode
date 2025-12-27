const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const CommunityComment = sequelize.define('CommunityComment', {
  comment_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  post_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'community_posts',
      key: 'post_id'
    }
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'user_id'
    }
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  is_anonymous: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'community_comments',
  timestamps: false
});

CommunityComment.associate = (models) => {
  CommunityComment.belongsTo(models.User, { foreignKey: 'user_id' });
  CommunityComment.belongsTo(models.CommunityPost, { foreignKey: 'post_id' });
};

module.exports = CommunityComment;
