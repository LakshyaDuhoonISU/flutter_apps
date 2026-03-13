// Community Routes
// Handles community forum posts and discussions

const express = require('express');
const router = express.Router();
const {
    getPosts,
    getPost,
    createPost,
    addReply,
    deleteReply,
    upvotePost,
    togglePinPost,
    toggleLockPost,
    deletePost,
} = require('../controllers/communityController');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   GET /api/community
// @desc    Get all community posts with pagination
// @access  Public
router.get('/', getPosts);

// @route   GET /api/community/:id
// @desc    Get single post with replies
// @access  Public
router.get('/:id', getPost);

// @route   POST /api/community
// @desc    Create new community post
// @access  Private
router.post('/', protect, createPost);

// @route   POST /api/community/reply/:postId
// @desc    Add reply to a post
// @access  Private
router.post('/reply/:postId', protect, addReply);

// @route   DELETE /api/community/reply/:postId/:replyId
// @desc    Delete a reply (Educator or reply owner)
// @access  Private
router.delete('/reply/:postId/:replyId', protect, deleteReply);

// @route   POST /api/community/upvote/:postId
// @desc    Upvote or remove upvote from a post
// @access  Private
router.post('/upvote/:postId', protect, upvotePost);

// @route   PUT /api/community/pin/:postId
// @desc    Pin or unpin a post (Educator only)
// @access  Private/Educator
router.put('/pin/:postId', protect, restrictTo('educator'), togglePinPost);

// @route   PUT /api/community/lock/:postId
// @desc    Lock or unlock a post (Educator only)
// @access  Private/Educator
router.put('/lock/:postId', protect, restrictTo('educator'), toggleLockPost);

// @route   DELETE /api/community/:postId
// @desc    Delete a post (Educator or post owner)
// @access  Private
router.delete('/:postId', protect, deletePost);

module.exports = router;
