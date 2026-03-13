// Current Affairs Controller
// Handles daily current affairs and quiz

const CurrentAffairs = require('../models/CurrentAffairs');

/**
 * @desc    Get today's current affairs
 * @route   GET /api/current-affairs/today
 * @access  Public
 */
const getTodayCurrentAffairs = async (req, res) => {
    try {
        // Get today's date (start of day)
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Find current affairs for today
        const currentAffairs = await CurrentAffairs.findOne({
            date: {
                $gte: today,
                $lt: new Date(today.getTime() + 24 * 60 * 60 * 1000),
            },
        }).populate('createdBy', 'name');

        // If no current affairs for today, get the most recent one
        if (!currentAffairs) {
            const latestAffairs = await CurrentAffairs.findOne()
                .sort({ date: -1 })
                .populate('createdBy', 'name');

            return res.status(200).json({
                success: true,
                message: 'No current affairs for today, showing latest',
                data: latestAffairs,
            });
        }

        res.status(200).json({
            success: true,
            data: currentAffairs,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching current affairs',
            error: error.message,
        });
    }
};

/**
 * @desc    Get current affairs by date range
 * @route   GET /api/current-affairs
 * @access  Public
 */
const getCurrentAffairs = async (req, res) => {
    try {
        const { startDate, endDate, category } = req.query;

        let query = {};

        // Filter by date range if provided
        if (startDate || endDate) {
            query.date = {};
            if (startDate) query.date.$gte = new Date(startDate);
            if (endDate) query.date.$lte = new Date(endDate);
        }

        // Filter by category if provided
        if (category) {
            query.category = category;
        }

        const currentAffairs = await CurrentAffairs.find(query)
            .populate('createdBy', 'name')
            .sort({ date: -1 })
            .limit(30); // Limit to 30 most recent

        res.status(200).json({
            success: true,
            count: currentAffairs.length,
            data: currentAffairs,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching current affairs',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new current affairs (Educator only)
 * @route   POST /api/current-affairs
 * @access  Private/Educator
 */
const createCurrentAffairs = async (req, res) => {
    try {
        const { date, title, summary, quiz, category, imageUrl } = req.body;

        // Validate input
        if (!date || !title || !summary) {
            return res.status(400).json({
                success: false,
                message: 'Please provide date, title and summary',
            });
        }

        // Delete all previous current affairs before creating new one
        await CurrentAffairs.deleteMany({});

        // Create current affairs
        const currentAffairs = await CurrentAffairs.create({
            date: new Date(date),
            title,
            summary,
            quiz: quiz || [],
            category: category || 'General',
            imageUrl: imageUrl || '',
            createdBy: req.user._id,
        });

        res.status(201).json({
            success: true,
            message: 'Current affairs created successfully',
            data: currentAffairs,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating current affairs',
            error: error.message,
        });
    }
};

/**
 * @desc    Update current affairs (Educator only)
 * @route   PUT /api/current-affairs/:id
 * @access  Private/Educator
 */
const updateCurrentAffairs = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, summary, quiz, category, imageUrl } = req.body;

        const currentAffairs = await CurrentAffairs.findById(id);

        if (!currentAffairs) {
            return res.status(404).json({
                success: false,
                message: 'Current affairs not found',
            });
        }

        // Update fields if provided
        if (title) currentAffairs.title = title;
        if (summary) currentAffairs.summary = summary;
        if (quiz) currentAffairs.quiz = quiz;
        if (category) currentAffairs.category = category;
        if (imageUrl !== undefined) currentAffairs.imageUrl = imageUrl;

        await currentAffairs.save();

        res.status(200).json({
            success: true,
            message: 'Current affairs updated successfully',
            data: currentAffairs,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating current affairs',
            error: error.message,
        });
    }
};

module.exports = {
    getTodayCurrentAffairs,
    getCurrentAffairs,
    createCurrentAffairs,
    updateCurrentAffairs,
};
