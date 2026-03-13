// Server Entry Point
// Main server file for UPSC Exam App Backend

// Import required packages
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const { initializeSocketHandlers } = require('./socket/liveClassHandlers');

// Load environment variables from .env file
dotenv.config();

// Connect to MongoDB database
connectDB();

// Initialize Express app
const app = express();

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
    cors: {
        origin: '*', // Allow all origins in development
        methods: ['GET', 'POST'],
        credentials: true,
    },
});

// Middleware
// Enable CORS for Flutter app to connect
app.use(cors({
    origin: '*', // Allow all origins in development
    credentials: true,
}));

// Parse JSON request bodies
app.use(express.json());

// Parse URL-encoded request bodies
app.use(express.urlencoded({ extended: true }));

// Request logger middleware (for debugging)
app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
});

// Import routes
const authRoutes = require('./routes/authRoutes');
const courseRoutes = require('./routes/courseRoutes');
const testRoutes = require('./routes/testRoutes');
const pyqRoutes = require('./routes/pyqRoutes');
const pyqSetRoutes = require('./routes/pyqSetRoutes');
const currentAffairsRoutes = require('./routes/currentAffairsRoutes');
const communityRoutes = require('./routes/communityRoutes');
const topperTalkRoutes = require('./routes/topperTalkRoutes');
const liveClassRoutes = require('./routes/liveClassRoutes');

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/test', testRoutes);
app.use('/api/pyq', pyqRoutes);
app.use('/api/pyq-sets', pyqSetRoutes);
app.use('/api/current-affairs', currentAffairsRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/topper-talks', topperTalkRoutes);
app.use('/api/live-class', liveClassRoutes);

// Root route
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'UPSC Exam App API is running',
        version: '1.0.0',
        endpoints: {
            auth: '/api/auth',
            courses: '/api/courses',
            tests: '/api/tests',
            currentAffairs: '/api/current-affairs',
            community: '/api/community',
        },
    });
});

// Initialize Socket.IO handlers for live class interactions
initializeSocketHandlers(io);

// 404 handler - Route not found
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.path,
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack);

    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    });
});

// Set port from environment variable or default to 5000
const PORT = process.env.PORT || 5000;

// Start server
server.listen(PORT, () => {
    console.log(`\n🚀 Server is running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 API URL: http://localhost:${PORT}`);
    console.log(`🔌 Socket.IO enabled for live class interactions`);
    console.log(`\n✅ Available endpoints:`);
    console.log(`   - Auth: http://localhost:${PORT}/api/auth`);
    console.log(`   - Courses: http://localhost:${PORT}/api/courses`);
    console.log(`   - Tests: http://localhost:${PORT}/api/tests`);
    console.log(`   - Current Affairs: http://localhost:${PORT}/api/current-affairs`);
    console.log(`   - Community: http://localhost:${PORT}/api/community\n`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    console.error('Unhandled Promise Rejection:', err);
    console.log('Shutting down server...');
    process.exit(1);
});
