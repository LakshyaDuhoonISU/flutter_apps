// Role Middleware
// Restricts access based on user role (student or educator)

/**
 * restrictTo - Middleware to restrict access to specific roles
 * @param  {...any} roles - Allowed roles (e.g., 'educator', 'student')
 * Usage: restrictTo('educator') - only educators can access
 */
const restrictTo = (...roles) => {
    return (req, res, next) => {
        // Check if user exists (should be set by authMiddleware)
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated',
            });
        }

        // Check if user's role is included in allowed roles
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Role '${req.user.role}' is not authorized to access this route`,
            });
        }

        next(); // User has correct role, continue
    };
};

module.exports = { restrictTo };
