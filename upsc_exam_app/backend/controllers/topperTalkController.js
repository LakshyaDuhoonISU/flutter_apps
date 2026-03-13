// TopperTalk Controller
// Handles topper talk videos and sessions

const TopperTalk = require('../models/TopperTalk');

/**
 * @desc    Get all topper talks
 * @route   GET /api/topper-talks
 * @access  Public
 */
const getTopperTalks = async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;

        // Calculate pagination
        const skip = (page - 1) * limit;

        // Get topper talks with pagination, sorted by year (newest first)
        const talks = await TopperTalk.find()
            .sort({ year: -1, rank: 1 })
            .skip(skip)
            .limit(parseInt(limit));

        // Get total count for pagination
        const total = await TopperTalk.countDocuments();

        res.status(200).json({
            success: true,
            count: talks.length,
            total,
            page: parseInt(page),
            pages: Math.ceil(total / limit),
            data: talks,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching topper talks',
            error: error.message,
        });
    }
};

/**
 * @desc    Get single topper talk by ID
 * @route   GET /api/topper-talks/:id
 * @access  Public
 */
const getTopperTalk = async (req, res) => {
    try {
        const { id } = req.params;

        const talk = await TopperTalk.findById(id);

        if (!talk) {
            return res.status(404).json({
                success: false,
                message: 'Topper talk not found',
            });
        }

        res.status(200).json({
            success: true,
            data: talk,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching topper talk',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new topper talk
 * @route   POST /api/topper-talks
 * @access  Private (Educator only)
 */
const createTopperTalk = async (req, res) => {
    try {
        const {
            title,
            topperName,
            rank,
            year,
            optional,
            videoUrl,
            thumbnail,
            durationMinutes,
            description,
        } = req.body;

        // Validate required fields
        if (!title || !topperName || !rank || !year || !videoUrl) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields',
            });
        }

        // Create topper talk
        const talk = await TopperTalk.create({
            title,
            topperName,
            rank,
            year,
            optional: optional || '',
            videoUrl,
            thumbnail: thumbnail || '',
            durationMinutes: durationMinutes || 0,
            description: description || '',
            isFree: true, // Always free for all students
        });

        res.status(201).json({
            success: true,
            message: 'Topper talk created successfully',
            data: talk,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating topper talk',
            error: error.message,
        });
    }
};

/**
 * @desc    Update topper talk
 * @route   PUT /api/topper-talks/:id
 * @access  Private (Educator only)
 */
const updateTopperTalk = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            title,
            topperName,
            rank,
            year,
            optional,
            videoUrl,
            thumbnail,
            durationMinutes,
            description,
        } = req.body;

        const talk = await TopperTalk.findById(id);

        if (!talk) {
            return res.status(404).json({
                success: false,
                message: 'Topper talk not found',
            });
        }

        // Update fields
        if (title) talk.title = title;
        if (topperName) talk.topperName = topperName;
        if (rank) talk.rank = rank;
        if (year) talk.year = year;
        if (optional !== undefined) talk.optional = optional;
        if (videoUrl) talk.videoUrl = videoUrl;
        if (thumbnail !== undefined) talk.thumbnail = thumbnail;
        if (durationMinutes !== undefined) talk.durationMinutes = durationMinutes;
        if (description !== undefined) talk.description = description;

        await talk.save();

        res.status(200).json({
            success: true,
            message: 'Topper talk updated successfully',
            data: talk,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating topper talk',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete topper talk
 * @route   DELETE /api/topper-talks/:id
 * @access  Private (Educator only)
 */
const deleteTopperTalk = async (req, res) => {
    try {
        const { id } = req.params;

        const talk = await TopperTalk.findById(id);

        if (!talk) {
            return res.status(404).json({
                success: false,
                message: 'Topper talk not found',
            });
        }

        await TopperTalk.findByIdAndDelete(id);

        res.status(200).json({
            success: true,
            message: 'Topper talk deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting topper talk',
            error: error.message,
        });
    }
};

module.exports = {
    getTopperTalks,
    getTopperTalk,
    createTopperTalk,
    updateTopperTalk,
    deleteTopperTalk,
};
