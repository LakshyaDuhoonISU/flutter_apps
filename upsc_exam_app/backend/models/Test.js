// Test Model
// Represents test series/mock tests for courses

const mongoose = require('mongoose');

const testSchema = new mongoose.Schema({
    // Course this test belongs to (optional for standalone test series)
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
        required: false,
        default: null,
    },

    // Test title
    title: {
        type: String,
        required: [true, 'Please add a test title'],
        trim: true,
    },

    // Test description
    description: {
        type: String,
        default: '',
    },

    // Test duration in minutes
    durationMinutes: {
        type: Number,
        required: [true, 'Please add test duration'],
    },

    // Total number of questions
    totalQuestions: {
        type: Number,
        required: [true, 'Please add total questions count'],
    },

    // Total marks for the test
    totalMarks: {
        type: Number,
        required: true,
        default: 100,
    },

    // Educator who created this test
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Is this test free or paid?
    isFree: {
        type: Boolean,
        default: false,
    },

    // Test creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('Test', testSchema);
