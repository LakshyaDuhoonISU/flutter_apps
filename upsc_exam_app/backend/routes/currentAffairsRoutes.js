// Current Affairs Routes
// Handles daily current affairs and quiz

const express = require('express');
const router = express.Router();
const {
    getTodayCurrentAffairs,
    getCurrentAffairs,
    createCurrentAffairs,
    updateCurrentAffairs,
} = require('../controllers/currentAffairsController');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   GET /api/current-affairs/today
// @desc    Get today's current affairs with quiz
// @access  Public
router.get('/today', getTodayCurrentAffairs);

// @route   GET /api/current-affairs
// @desc    Get current affairs by date range or category
// @access  Public
router.get('/', getCurrentAffairs);

// @route   POST /api/current-affairs
// @desc    Create new current affairs (Educator only)
// @access  Private/Educator
router.post('/', protect, restrictTo('educator'), createCurrentAffairs);

// @route   PUT /api/current-affairs/:id
// @desc    Update current affairs (Educator only)
// @access  Private/Educator
router.put('/:id', protect, restrictTo('educator'), updateCurrentAffairs);

module.exports = router;
