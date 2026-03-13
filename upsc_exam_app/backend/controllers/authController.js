// Authentication Controller
// Handles user registration and login

const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * generateToken - Helper function to generate JWT token
 * @param {string} id - User ID
 * @returns {string} JWT token
 */
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE,
    });
};

/**
 * @desc    Register new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        // Validate input
        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide name, email and password',
            });
        }

        // Check if user already exists
        const userExists = await User.findOne({ email });

        if (userExists) {
            return res.status(400).json({
                success: false,
                message: 'User already exists with this email',
            });
        }

        // Create user
        const user = await User.create({
            name,
            email,
            password,
            role: role || 'student', // Default to student if not specified
        });

        // Generate token
        const token = generateToken(user._id);

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                subscriptionType: user.subscriptionType,
                experience: user.experience,
                token,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error during registration',
            error: error.message,
        });
    }
};

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide email and password',
            });
        }

        // Find user with password field (normally excluded)
        const user = await User.findOne({ email }).select('+password');

        // Check if user exists and password matches
        if (!user || !(await user.matchPassword(password))) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password',
            });
        }

        // Generate token
        const token = generateToken(user._id);

        res.status(200).json({
            success: true,
            message: 'Login successful',
            data: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                subscriptionType: user.subscriptionType,
                experience: user.experience,
                enrolledCourses: user.enrolledCourses,
                token,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error during login',
            error: error.message,
        });
    }
};

/**
 * @desc    Get current logged in user
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = async (req, res) => {
    try {
        // req.user is set by authMiddleware
        const user = await User.findById(req.user._id)
            .populate('enrolledCourses', 'title subject price');

        res.status(200).json({
            success: true,
            data: user,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message,
        });
    }
};

/**
 * @desc    Upgrade user subscription
 * @route   PUT /api/auth/upgrade
 * @access  Private
 */
const upgradeSubscription = async (req, res) => {
    try {
        const { subscriptionType } = req.body;

        // Validate subscription type
        const validTypes = ['plus', 'individual', 'test-series', 'none'];
        if (!subscriptionType || !validTypes.includes(subscriptionType)) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a valid subscription type: plus, individual, test-series, or none',
            });
        }

        // Get current user to check if subscription is changing
        const currentUser = await User.findById(req.user._id);
        if (!currentUser) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // If subscription type is changing, clear enrolled courses and bookmarks
        const updateData = { subscriptionType };
        if (currentUser.subscriptionType !== subscriptionType) {
            updateData.enrolledCourses = [];
            updateData.bookmarkedClasses = [];
            updateData.classNotes = [];
        }

        // Update user subscription
        const user = await User.findByIdAndUpdate(
            req.user._id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Subscription upgraded successfully',
            data: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                subscriptionType: user.subscriptionType,
                enrolledCourses: user.enrolledCourses,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error during subscription upgrade',
            error: error.message,
        });
    }
};

/**
 * @desc    Update user profile
 * @route   PUT /api/auth/profile
 * @access  Private
 */
const updateProfile = async (req, res) => {
    try {
        const { name, experience } = req.body;

        const updateData = {};
        if (name) updateData.name = name;
        if (experience !== undefined) updateData.experience = experience;

        // Update user profile
        const user = await User.findByIdAndUpdate(
            req.user._id,
            updateData,
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                subscriptionType: user.subscriptionType,
                experience: user.experience,
                enrolledCourses: user.enrolledCourses,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error during profile update',
            error: error.message,
        });
    }
};

/**
 * @desc    Get educator stats (total students count)
 * @route   GET /api/auth/educator-stats
 * @access  Private
 */
const getEducatorStats = async (req, res) => {
    try {
        const Course = require('../models/Course');

        // Get all courses by this educator
        const courses = await Course.find({ educatorId: req.user._id });

        // Calculate total students
        const totalStudents = courses.reduce((sum, course) => sum + course.enrolledStudents, 0);

        res.status(200).json({
            success: true,
            data: {
                totalStudents,
                totalCourses: courses.length,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching educator stats',
            error: error.message,
        });
    }
};

module.exports = {
    register,
    login,
    getMe,
    upgradeSubscription,
    updateProfile,
    getEducatorStats,
};
