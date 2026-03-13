// PYQ Set Controller
// Handles Previous Year Question sets

const PYQSet = require('../models/PYQSet');

/**
 * @desc    Get all PYQ sets (with optional filters)
 * @route   GET /api/pyq-sets
 * @access  Private
 */
const getAllPYQSets = async (req, res) => {
    try {
        const { courseId, year, subject } = req.query;

        let query = {};

        // Filter by course
        if (courseId) {
            query.courseId = courseId;
        }

        // Filter by year
        if (year) {
            query.year = parseInt(year);
        }

        // Filter by subject
        if (subject) {
            query.subject = subject;
        }

        const pyqSets = await PYQSet.find(query)
            .populate('courseId', 'name')
            .populate('createdBy', 'name')
            .sort({ year: -1, createdAt: -1 });

        res.status(200).json({
            success: true,
            count: pyqSets.length,
            data: pyqSets,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching PYQ sets',
            error: error.message,
        });
    }
};

/**
 * @desc    Get single PYQ set by ID
 * @route   GET /api/pyq-sets/:id
 * @access  Private
 */
const getPYQSetById = async (req, res) => {
    try {
        const { id } = req.params;

        const pyqSet = await PYQSet.findById(id)
            .populate('courseId', 'name')
            .populate('createdBy', 'name');

        if (!pyqSet) {
            return res.status(404).json({
                success: false,
                message: 'PYQ set not found',
            });
        }

        res.status(200).json({
            success: true,
            data: pyqSet,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching PYQ set',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new PYQ set (Educator only)
 * @route   POST /api/pyq-sets
 * @access  Private/Educator
 */
const createPYQSet = async (req, res) => {
    try {
        const { title, year, subject, description, courseId, questions } = req.body;

        // Validate input
        if (!title || !year || !subject || !courseId) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title, year, subject and courseId',
            });
        }

        if (!questions || questions.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Please provide at least one question',
            });
        }

        // Validate each question
        for (let i = 0; i < questions.length; i++) {
            const q = questions[i];
            if (!q.question || !q.options || q.options.length !== 4 || q.correctAnswer === undefined) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid question at index ${i}. Each question must have question text, 4 options, and a correct answer.`,
                });
            }
        }

        // Create PYQ set
        const pyqSet = await PYQSet.create({
            title,
            year: parseInt(year),
            subject,
            description: description || '',
            courseId,
            questions,
            createdBy: req.user._id,
        });

        // Populate references
        await pyqSet.populate('courseId', 'name');
        await pyqSet.populate('createdBy', 'name');

        res.status(201).json({
            success: true,
            message: 'PYQ set created successfully',
            data: pyqSet,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating PYQ set',
            error: error.message,
        });
    }
};

/**
 * @desc    Update PYQ set (Educator only)
 * @route   PUT /api/pyq-sets/:id
 * @access  Private/Educator
 */
const updatePYQSet = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, year, subject, description, questions } = req.body;

        const pyqSet = await PYQSet.findById(id);

        if (!pyqSet) {
            return res.status(404).json({
                success: false,
                message: 'PYQ set not found',
            });
        }

        // Check if the user is the creator
        if (pyqSet.createdBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this PYQ set',
            });
        }

        // Update fields
        if (title) pyqSet.title = title;
        if (year) pyqSet.year = parseInt(year);
        if (subject) pyqSet.subject = subject;
        if (description !== undefined) pyqSet.description = description;
        if (questions) {
            // Validate questions
            for (let i = 0; i < questions.length; i++) {
                const q = questions[i];
                if (!q.question || !q.options || q.options.length !== 4 || q.correctAnswer === undefined) {
                    return res.status(400).json({
                        success: false,
                        message: `Invalid question at index ${i}`,
                    });
                }
            }
            pyqSet.questions = questions;
        }

        await pyqSet.save();

        // Populate references
        await pyqSet.populate('courseId', 'name');
        await pyqSet.populate('createdBy', 'name');

        res.status(200).json({
            success: true,
            message: 'PYQ set updated successfully',
            data: pyqSet,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating PYQ set',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete PYQ set (Educator only)
 * @route   DELETE /api/pyq-sets/:id
 * @access  Private/Educator
 */
const deletePYQSet = async (req, res) => {
    try {
        const { id } = req.params;

        const pyqSet = await PYQSet.findById(id);

        if (!pyqSet) {
            return res.status(404).json({
                success: false,
                message: 'PYQ set not found',
            });
        }

        // Check if the user is the creator
        if (pyqSet.createdBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this PYQ set',
            });
        }

        await pyqSet.deleteOne();

        res.status(200).json({
            success: true,
            message: 'PYQ set deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting PYQ set',
            error: error.message,
        });
    }
};

module.exports = {
    getAllPYQSets,
    getPYQSetById,
    createPYQSet,
    updatePYQSet,
    deletePYQSet,
};
