// PYQ Routes
// Handles Previous Year Questions CRUD operations

const express = require('express');
const router = express.Router();
const {
    getAllPYQ,
    getPYQById,
    createPYQ,
    updatePYQ,
    deletePYQ,
} = require('../controllers/pyqController');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   GET /api/pyq
// @desc    Get all previous year questions
// @access  Public
router.get('/', getAllPYQ);

// @route   GET /api/pyq/:id
// @desc    Get single PYQ by ID
// @access  Public
router.get('/:id', getPYQById);

// @route   POST /api/pyq
// @desc    Create new PYQ (Educator only)
// @access  Private/Educator
router.post('/', protect, restrictTo('educator'), createPYQ);

// @route   PUT /api/pyq/:id
// @desc    Update PYQ (Educator only)
// @access  Private/Educator
router.put('/:id', protect, restrictTo('educator'), updatePYQ);

// @route   DELETE /api/pyq/:id
// @desc    Delete PYQ (Educator only)
// @access  Private/Educator
router.delete('/:id', protect, restrictTo('educator'), deletePYQ);

module.exports = router;
