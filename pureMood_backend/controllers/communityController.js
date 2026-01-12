const CommunityPost = require('../models/CommunityPost');
const CommunityComment = require('../models/CommunityComment');
const CommunityLike = require('../models/CommunityLike');
const User = require('../models/User');
const { Op } = require('sequelize');
const { moderateContent } = require('../utils/contentModeration');

exports.getAllPosts = async (req, res) => {
  try {
    const { category } = req.query;
    
    const whereClause = category ? { category } : {};
    
    const posts = await CommunityPost.findAll({
      where: whereClause,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: User,
          attributes: ['user_id', 'name', 'picture']
        },
        {
          model: CommunityPost,
          as: 'OriginalPost',
          required: false,
          include: [{
            model: User,
            attributes: ['user_id', 'name', 'picture']
          }]
        }
      ]
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

      // معالجة بيانات المنشور الأصلي في حالة إعادة النشر
      if (postData.OriginalPost) {
        if (postData.OriginalPost.is_anonymous) {
          postData.OriginalPost.User = {
            user_id: null,
            name: 'Anonymous',
            picture: null
          };
        }
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

    // فحص العنوان والمحتوى للكلمات السيئة
    const titleModeration = moderateContent(title);
    const contentModeration = moderateContent(content);
    
    // إذا كان هناك محتوى سيء في العنوان أو المحتوى، يتم رفض المشاركة
    if (titleModeration.action === 'reject' || contentModeration.action === 'reject') {
      const allFoundWords = [...titleModeration.foundWords, ...contentModeration.foundWords];
      return res.status(400).json({ 
        message: 'Post contains inappropriate content and cannot be posted',
        reason: titleModeration.reason || contentModeration.reason,
        foundWords: allFoundWords
      });
    }

    // استخدام المحتوى المنظف إذا كان هناك فلترة
    const finalTitle = titleModeration.action === 'filter' ? titleModeration.cleanText : title;
    const finalContent = contentModeration.action === 'filter' ? contentModeration.cleanText : content;

    const post = await CommunityPost.create({
      user_id,
      title: finalTitle,
      content: finalContent,
      category: category || 'general',
      is_anonymous: is_anonymous || false
    });

    const wasFiltered = titleModeration.action === 'filter' || contentModeration.action === 'filter';
    const responseMessage = wasFiltered 
      ? 'Post created successfully with some words filtered'
      : 'Post created successfully';

    res.status(201).json({ 
      message: responseMessage,
      post,
      moderation: {
        wasFiltered: wasFiltered,
        titleRiskLevel: titleModeration.riskLevel,
        contentRiskLevel: contentModeration.riskLevel
      }
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
      attributes: ['comment_id', 'post_id', 'user_id', 'content', 'is_anonymous', 'created_at'],
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

    // فحص المحتوى للكلمات السيئة
    let moderation;
    try {
      moderation = moderateContent(content);
    } catch (moderationError) {
      console.error('Error during content moderation:', moderationError);
      return res.status(500).json({ 
        message: 'خطأ في معالجة المحتوى / Error processing content',
        error: 'moderation_failed'
      });
    }
    
    // إذا كان هناك خطأ حرج في المعالجة
    if (moderation.criticalError) {
      return res.status(500).json({ 
        message: 'Critical error processing content',
        reason: moderation.reason
      });
    }
    
    // إذا كان المحتوى يحتوي على كلمات سيئة كثيرة، يتم رفضه
    // سياسة صارمة: أي كلمات سيئة = رفض (حتى لو كان يمكن فلترتها سابقاً)
    if (moderation.action !== 'approve') {
      return res.status(400).json({ 
        message: 'Comment contains inappropriate content and cannot be posted',
        reason: moderation.reason,
        foundWords: moderation.foundWords
      });
    }

    const post = await CommunityPost.findByPk(post_id);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const comment = await CommunityComment.create({
      post_id,
      user_id,
      content: content,
      is_anonymous: is_anonymous || false
    });

    // سجل معلومات المراقبة في console للمراجعة
    if (moderation.action !== 'approve') {
      console.log(`🛡️ Content moderation applied:`, {
        comment_id: comment.comment_id,
        user_id: user_id,
        action: moderation.action,
        risk_level: moderation.riskLevel,
        found_words: moderation.foundWords,
        original_content: moderation.action === 'filter' ? content : null
      });
    }

    await post.update({ comments_count: post.comments_count + 1 });

    res.status(201).json({ 
      message: 'Comment created successfully',
      comment,
      moderation: null
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

exports.repostPost = async (req, res) => {
  try {
    const { post_id } = req.params;
    const { content, is_anonymous } = req.body;
    const user_id = req.user.user_id;

    // التحقق من وجود المنشور الأصلي
    const originalPost = await CommunityPost.findByPk(post_id);
    if (!originalPost) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // التحقق من أن المستخدم لا يعيد نشر منشوره الخاص
    if (originalPost.user_id === user_id) {
      return res.status(400).json({ 
        message: 'You cannot repost your own post' 
      });
    }

    // التحقق من أن المستخدم لم يقم بإعادة نشر هذا المنشور من قبل
    const existingRepost = await CommunityPost.findOne({
      where: {
        user_id: user_id,
        original_post_id: post_id
      }
    });

    if (existingRepost) {
      return res.status(400).json({ 
        message: 'You have already reposted this post' 
      });
    }

    let finalContent = '';
    let moderation = null;

    // إذا كان هناك محتوى إضافي، قم بفحصه
    if (content && content.trim()) {
      moderation = moderateContent(content.trim());
      
      if (moderation.action === 'reject') {
        return res.status(400).json({ 
          message: 'المحتوى الإضافي يحتوي على محتوى غير مناسب / Additional content contains inappropriate material',
          reason: moderation.reason,
          foundWords: moderation.foundWords
        });
      }

      finalContent = moderation.action === 'filter' ? moderation.cleanText : content.trim();
    }

    // إنشاء إعادة النشر
    const repost = await CommunityPost.create({
      user_id,
      title: originalPost.title,
      content: finalContent,
      category: originalPost.category,
      original_post_id: post_id,
      is_anonymous: is_anonymous || false
    });

    // تحديث عداد إعادة النشر للمنشور الأصلي
    await originalPost.update({ 
      repost_count: originalPost.repost_count + 1 
    });

    const responseMessage = moderation && moderation.action === 'filter' 
      ? 'Repost created successfully with some words filtered'
      : 'Repost created successfully';

    res.status(201).json({ 
      message: responseMessage,
      repost,
      moderation: moderation ? {
        wasFiltered: moderation.action === 'filter',
        riskLevel: moderation.riskLevel
      } : null
    });
  } catch (error) {
    console.error('Error creating repost:', error);
    res.status(500).json({ message: 'Error creating repost', error: error.message });
  }
};
