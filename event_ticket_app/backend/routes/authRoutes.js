const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/auth/register
 * Register a new user
 * Body: { name, email, password, role }
 */
router.post('/register', async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        // Validate required fields
        if (!name || !email || !password || !role) {
            return res.status(400).json({ 
                success: false, 
                message: 'Please provide all required fields: name, email, password, role' 
            });
        }

        // Validate role
        const validRoles = ['user', 'admin', 'organizer'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ 
                success: false, 
                message: 'Invalid role. Must be: user, admin, or organizer' 
            });
        }

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ 
                success: false, 
                message: 'User with this email already exists' 
            });
        }

        // Hash password using bcrypt
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create new user
        const user = new User({
            name,
            email,
            password: hashedPassword,
            role
        });

        await user.save();

        // Return success response (don't send password)
        res.status(201).json({ 
            success: true, 
            message: 'User registered successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Server error during registration',
            error: error.message 
        });
    }
});

/**
 * POST /api/auth/login
 * Login user and generate JWT token
 * Body: { email, password }
 */
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate required fields
        if (!email || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Please provide email and password' 
            });
        }

        // Find user by email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid email' 
            });
        }

        // Verify password using bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid password' 
            });
        }

        // Generate JWT token (expires in 7 days)
        const token = jwt.sign(
            { 
                id: user._id, 
                email: user.email, 
                role: user.role 
            },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Return success response with token
        res.status(200).json({ 
            success: true, 
            message: 'Login successful',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Server error during login',
            error: error.message 
        });
    }
});

module.exports = router;
