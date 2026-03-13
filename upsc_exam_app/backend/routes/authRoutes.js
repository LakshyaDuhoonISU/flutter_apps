// Authentication Routes
// Handles user registration, login, and profile

const express = require('express');
const router = express.Router();
const { register, login, getMe, upgradeSubscription, updateProfile, getEducatorStats } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

// @route   POST /api/auth/register
// @desc    Register a new user (student or educator)
// @access  Public
router.post('/register', register);

// @route   POST /api/auth/login
// @desc    Login user and get token
// @access  Public
router.post('/login', login);

// @route   GET /api/auth/me
// @desc    Get current logged in user
// @access  Private
router.get('/me', protect, getMe);

// @route   PUT /api/auth/upgrade
// @desc    Upgrade user subscription
// @access  Private
router.put('/upgrade', protect, upgradeSubscription);

// @route   PUT /api/auth/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', protect, updateProfile);

// @route   GET /api/auth/educator-stats
// @desc    Get educator statistics
// @access  Private
router.get('/educator-stats', protect, getEducatorStats);

module.exports = router;
