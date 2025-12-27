const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  getAllPosts,
  createPost,
  getPostById,
  deletePost,
  likePost,
  getComments,
  createComment,
  deleteComment
} = require('../controllers/communityController');

router.get('/posts', verifyToken, getAllPosts);
router.post('/posts', verifyToken, createPost);
router.get('/posts/:post_id', verifyToken, getPostById);
router.delete('/posts/:post_id', verifyToken, deletePost);
router.post('/posts/:post_id/like', verifyToken, likePost);
router.get('/posts/:post_id/comments', verifyToken, getComments);
router.post('/posts/:post_id/comments', verifyToken, createComment);
router.delete('/comments/:comment_id', verifyToken, deleteComment);

module.exports = router;
