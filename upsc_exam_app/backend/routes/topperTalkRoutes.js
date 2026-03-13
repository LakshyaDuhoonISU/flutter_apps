// TopperTalk Routes
// Handles routes for topper talk videos

const express = require('express');
const router = express.Router();
const {
    getTopperTalks,
    getTopperTalk,
    createTopperTalk,
    updateTopperTalk,
    deleteTopperTalk,
} = require('../controllers/topperTalkController');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   GET /api/topper-talks
// @desc    Get all topper talks
// @access  Public
router.get('/', getTopperTalks);

// @route   GET /api/topper-talks/:id
// @desc    Get single topper talk and increment views
// @access  Public
router.get('/:id', getTopperTalk);

// @route   POST /api/topper-talks
// @desc    Create new topper talk
// @access  Private (Educator only)
router.post('/', protect, restrictTo('educator'), createTopperTalk);

// @route   PUT /api/topper-talks/:id
// @desc    Update topper talk
// @access  Private (Educator only)
router.put('/:id', protect, restrictTo('educator'), updateTopperTalk);

// @route   DELETE /api/topper-talks/:id
// @desc    Delete topper talk
// @access  Private (Educator only)
router.delete('/:id', protect, restrictTo('educator'), deleteTopperTalk);

module.exports = router;
