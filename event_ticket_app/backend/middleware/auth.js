const jwt = require('jsonwebtoken');

// Secret key for JWT
const JWT_SECRET = 'itm';

/**
 * Middleware to verify JWT token and authenticate user
 * Adds user information to req.user if token is valid
 */
const authenticate = async (req, res, next) => {
    try {
        // Get token from Authorization header
        const token = req.header('Authorization')?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({ 
                success: false, 
                message: 'Access denied. No token provided.' 
            });
        }

        // Verify token
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ 
            success: false, 
            message: 'Invalid token.' 
        });
    }
};

/**
 * Middleware to check if user has required role
 * @param {Array} roles - Array of allowed roles
 */
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ 
                success: false, 
                message: 'Unauthorized. Please login first.' 
            });
        }

        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ 
                success: false, 
                message: `Access denied. Required role: ${roles.join(' or ')}` 
            });
        }

        next();
    };
};

module.exports = { authenticate, authorize, JWT_SECRET };
