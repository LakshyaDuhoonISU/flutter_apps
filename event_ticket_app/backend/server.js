const express = require('express');
const cors = require('cors');
const db = require('./db');

// Import routes
const authRoutes = require('./routes/authRoutes');
const eventRoutes = require('./routes/eventRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
app.use(cors("*"));
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/admin', adminRoutes);

// Start server
app.listen(3000, () => {
    console.log(`Server running on port 3000`);
});

module.exports = app;
