const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const CommunityPost = sequelize.define('CommunityPost', {
  post_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'user_id'
    }
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  category: {
    type: DataTypes.ENUM('support', 'question', 'story', 'tip', 'general'),
    defaultValue: 'general'
  },
  likes_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  comments_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
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
  tableName: 'community_posts',
  timestamps: false
});

CommunityPost.associate = (models) => {
  CommunityPost.belongsTo(models.User, { foreignKey: 'user_id' });
  CommunityPost.hasMany(models.CommunityComment, { foreignKey: 'post_id' });
  CommunityPost.hasMany(models.CommunityLike, { foreignKey: 'post_id' });
};

module.exports = CommunityPost;
