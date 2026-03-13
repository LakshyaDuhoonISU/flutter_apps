// Previous Year Questions Controller
// Handles CRUD operations for previous year questions

const Question = require('../models/Question');
const User = require('../models/User');

/**
 * @desc    Get all previous year questions
 * @route   GET /api/pyq
 * @access  Public
 */
const getAllPYQ = async (req, res) => {
    try {
        const questions = await Question.find({ isPreviousYear: true })
            .sort({ year: -1, createdAt: -1 });

        res.status(200).json({
            success: true,
            count: questions.length,
            data: questions,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching PYQ',
            error: error.message,
        });
    }
};

/**
 * @desc    Get a single PYQ by ID
 * @route   GET /api/pyq/:id
 * @access  Public
 */
const getPYQById = async (req, res) => {
    try {
        const question = await Question.findById(req.params.id);

        if (!question || !question.isPreviousYear) {
            return res.status(404).json({
                success: false,
                message: 'PYQ not found',
            });
        }

        res.status(200).json({
            success: true,
            data: question,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching PYQ',
            error: error.message,
        });
    }
};

/**
 * @desc    Create a new PYQ
 * @route   POST /api/pyq
 * @access  Private/Educator
 */
const createPYQ = async (req, res) => {
    try {
        const {
            question,
            options,
            correctAnswer,
            explanation,
            year,
            difficulty,
            topicId,
        } = req.body;

        // Validation
        if (!question || !options || options.length !== 4 || correctAnswer === undefined || !year) {
            return res.status(400).json({
                success: false,
                message: 'Please provide question, 4 options, correct answer, and year',
            });
        }

        const pyq = await Question.create({
            question,
            options,
            correctAnswer,
            explanation: explanation || '',
            year,
            difficulty: difficulty || 'Medium',
            topicId,
            isPreviousYear: true,
            testId: null, // PYQ doesn't belong to any test
        });

        res.status(201).json({
            success: true,
            message: 'PYQ created successfully',
            data: pyq,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating PYQ',
            error: error.message,
        });
    }
};

/**
 * @desc    Update a PYQ
 * @route   PUT /api/pyq/:id
 * @access  Private/Educator
 */
const updatePYQ = async (req, res) => {
    try {
        const {
            question,
            options,
            correctAnswer,
            explanation,
            year,
            difficulty,
            topicId,
        } = req.body;

        const pyq = await Question.findById(req.params.id);

        if (!pyq || !pyq.isPreviousYear) {
            return res.status(404).json({
                success: false,
                message: 'PYQ not found',
            });
        }

        // Update fields
        if (question) pyq.question = question;
        if (options && options.length === 4) pyq.options = options;
        if (correctAnswer !== undefined) pyq.correctAnswer = correctAnswer;
        if (explanation !== undefined) pyq.explanation = explanation;
        if (year) pyq.year = year;
        if (difficulty) pyq.difficulty = difficulty;
        if (topicId !== undefined) pyq.topicId = topicId;

        await pyq.save();

        res.status(200).json({
            success: true,
            message: 'PYQ updated successfully',
            data: pyq,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating PYQ',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete a PYQ
 * @route   DELETE /api/pyq/:id
 * @access  Private/Educator
 */
const deletePYQ = async (req, res) => {
    try {
        const pyq = await Question.findById(req.params.id);

        if (!pyq || !pyq.isPreviousYear) {
            return res.status(404).json({
                success: false,
                message: 'PYQ not found',
            });
        }

        await pyq.deleteOne();

        res.status(200).json({
            success: true,
            message: 'PYQ deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting PYQ',
            error: error.message,
        });
    }
};

module.exports = {
    getAllPYQ,
    getPYQById,
    createPYQ,
    updatePYQ,
    deletePYQ,
};
