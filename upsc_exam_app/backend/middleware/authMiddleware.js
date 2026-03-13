// Authentication Middleware
// Protects routes that require user to be logged in

const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * protect - Middleware to verify JWT token
 * Adds user object to request if token is valid
 */
const protect = async (req, res, next) => {
    let token;

    // Check if authorization header exists and starts with 'Bearer'
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header (format: "Bearer TOKEN")
            token = req.headers.authorization.split(' ')[1];

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Get user from token (exclude password)
            req.user = await User.findById(decoded.id).select('-password');

            // Check if user exists
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    message: 'User not found',
                });
            }

            next(); // Continue to next middleware/route handler
        } catch (error) {
            console.error(error);
            return res.status(401).json({
                success: false,
                message: 'Not authorized, token failed',
            });
        }
    }

    // If no token found
    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Not authorized, no token',
        });
    }
};

/**
 * optionalProtect - Middleware to optionally verify JWT token
 * Sets user object to request if token is valid, but doesn't fail if no token
 */
const optionalProtect = async (req, res, next) => {
    let token;

    // Check if authorization header exists and starts with 'Bearer'
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header (format: "Bearer TOKEN")
            token = req.headers.authorization.split(' ')[1];

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Get user from token (exclude password)
            req.user = await User.findById(decoded.id).select('-password');
        } catch (error) {
            // Silently continue without user if token is invalid
            console.log('Optional auth: Invalid token');
        }
    }

    // Continue regardless of whether user was found
    next();
};

module.exports = { protect, optionalProtect };
