const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
    try {
        const token = req.headers.token;

        if (!token) {
            return res.status(401).json({ message: 'Access denied. No token provided.' });
        }

        const decodedToken = jwt.verify(token, 'itm');
        if (!decodedToken) {
            return res.status(401).json({ message: 'Invalid token.' });
        }

        req.user = decodedToken;
        next();
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = authMiddleware;