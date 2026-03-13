// PYQ Set Routes
const express = require('express');
const router = express.Router();
const {
    getAllPYQSets,
    getPYQSetById,
    createPYQSet,
    updatePYQSet,
    deletePYQSet,
} = require('../controllers/pyqSetController');

const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// Get all PYQ sets (with optional filters)
router.get('/', protect, getAllPYQSets);

// Get single PYQ set by ID
router.get('/:id', protect, getPYQSetById);

// Create new PYQ set (Educator only)
router.post('/', protect, restrictTo('educator', 'admin'), createPYQSet);

// Update PYQ set (Educator only)
router.put('/:id', protect, restrictTo('educator', 'admin'), updatePYQSet);

// Delete PYQ set (Educator only)
router.delete('/:id', protect, restrictTo('educator', 'admin'), deletePYQSet);

module.exports = router;
