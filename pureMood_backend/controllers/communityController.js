const CommunityPost = require('../models/CommunityPost');
const CommunityComment = require('../models/CommunityComment');
const CommunityLike = require('../models/CommunityLike');
const User = require('../models/User');
const { Op } = require('sequelize');

exports.getAllPosts = async (req, res) => {
  try {
    const { category } = req.query;
    
    const whereClause = category ? { category } : {};
    
    const posts = await CommunityPost.findAll({
      where: whereClause,
      order: [['created_at', 'DESC']],
      include: [{
        model: User,
        attributes: ['user_id', 'name', 'picture']
      }]
    });

    const postsWithUserData = await Promise.all(posts.map(async (post) => {
      const postData = post.toJSON();
      
      if (postData.is_anonymous) {
        postData.User = {
          user_id: null,
          name: 'Anonymous',
          picture: null
        };
      }
      
      return postData;
    }));

    res.json({ posts: postsWithUserData });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: 'Error fetching posts', error: error.message });
  }
};

exports.createPost = async (req, res) => {
  try {
    const { title, content, category, is_anonymous } = req.body;
    const user_id = req.user.user_id;

    if (!title || !content) {
      return res.status(400).json({ message: 'Title and content are required' });
    }

    const post = await CommunityPost.create({
      user_id,
      title,
      content,
      category: category || 'general',
      is_anonymous: is_anonymous || false
    });

    res.status(201).json({ 
      message: 'Post created successfully',
      post 
    });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ message: 'Error creating post', error: error.message });
  }
};

exports.getPostById = async (req, res) => {
  try {
    const { post_id } = req.params;

    const post = await CommunityPost.findByPk(post_id, {
      include: [{
        model: User,
        attributes: ['user_id', 'name', 'picture']
      }]
    });

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const postData = post.toJSON();
    
    if (postData.is_anonymous) {
      postData.User = {
        user_id: null,
        name: 'Anonymous',
        picture: null
      };
    }

    res.json({ post: postData });
  } catch (error) {
    console.error('Error fetching post:', error);
    res.status(500).json({ message: 'Error fetching post', error: error.message });
  }
};

exports.deletePost = async (req, res) => {
  try {
    const { post_id } = req.params;
    const user_id = req.user.user_id;

    const post = await CommunityPost.findByPk(post_id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    if (post.user_id !== user_id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'You can only delete your own posts' });
    }

    await post.destroy();
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ message: 'Error deleting post', error: error.message });
  }
};

exports.likePost = async (req, res) => {
  try {
    const { post_id } = req.params;
    const user_id = req.user.user_id;

    const post = await CommunityPost.findByPk(post_id);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const existingLike = await CommunityLike.findOne({
      where: { post_id, user_id }
    });

    if (existingLike) {
      await existingLike.destroy();
      await post.update({ likes_count: post.likes_count - 1 });
      return res.json({ message: 'Post unliked', liked: false, likes_count: post.likes_count - 1 });
    } else {
      await CommunityLike.create({ post_id, user_id });
      await post.update({ likes_count: post.likes_count + 1 });
      return res.json({ message: 'Post liked', liked: true, likes_count: post.likes_count + 1 });
    }
  } catch (error) {
    console.error('Error liking post:', error);
    res.status(500).json({ message: 'Error liking post', error: error.message });
  }
};

exports.getComments = async (req, res) => {
  try {
    const { post_id } = req.params;

    const comments = await CommunityComment.findAll({
      where: { post_id },
      order: [['created_at', 'DESC']],
      include: [{
        model: User,
        attributes: ['user_id', 'name', 'picture']
      }]
    });

    const commentsWithUserData = comments.map(comment => {
      const commentData = comment.toJSON();
      
      if (commentData.is_anonymous) {
        commentData.User = {
          user_id: null,
          name: 'Anonymous',
          picture: null
        };
      }
      
      return commentData;
    });

    res.json({ comments: commentsWithUserData });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ message: 'Error fetching comments', error: error.message });
  }
};

exports.createComment = async (req, res) => {
  try {
    const { post_id } = req.params;
    const { content, is_anonymous } = req.body;
    const user_id = req.user.user_id;

    if (!content) {
      return res.status(400).json({ message: 'Content is required' });
    }

    const post = await CommunityPost.findByPk(post_id);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const comment = await CommunityComment.create({
      post_id,
      user_id,
      content,
      is_anonymous: is_anonymous || false
    });

    await post.update({ comments_count: post.comments_count + 1 });

    res.status(201).json({ 
      message: 'Comment created successfully',
      comment 
    });
  } catch (error) {
    console.error('Error creating comment:', error);
    res.status(500).json({ message: 'Error creating comment', error: error.message });
  }
};

exports.deleteComment = async (req, res) => {
  try {
    const { comment_id } = req.params;
    const user_id = req.user.user_id;

    const comment = await CommunityComment.findByPk(comment_id);

    if (!comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    const post = await CommunityPost.findByPk(comment.post_id);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const isCommentOwner = comment.user_id === user_id;
    const isPostOwner = post.user_id === user_id;
    const isAdmin = req.user.role === 'admin';

    if (!isCommentOwner && !isPostOwner && !isAdmin) {
      return res.status(403).json({ 
        message: 'You can only delete your own comments, comments on your posts, or if you are an admin' 
      });
    }

    await post.update({ comments_count: Math.max(0, post.comments_count - 1) });
    await comment.destroy();
    
    res.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({ message: 'Error deleting comment', error: error.message });
  }
};
