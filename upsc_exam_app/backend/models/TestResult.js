// TestResult Model
// Stores test attempt results for students

const mongoose = require('mongoose');

const testResultSchema = new mongoose.Schema({
    // Student who attempted the test
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Test that was attempted
    testId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Test',
        required: true,
    },

    // Array of answers with details
    answers: [{
        questionId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Question',
        },
        selectedOption: {
            type: Number, // Index of selected option (0-3) or -1 for unattempted
        },
        isCorrect: {
            type: Boolean,
        },
        timeTaken: {
            type: Number, // Time taken in seconds for this question
            default: 0,
        },
    }],

    // Total score obtained
    score: {
        type: Number,
        required: true,
    },

    // Number of correct answers
    correctCount: {
        type: Number,
        required: true,
        default: 0,
    },

    // Number of wrong answers
    wrongCount: {
        type: Number,
        required: true,
        default: 0,
    },

    // Number of unattempted questions
    unattemptedCount: {
        type: Number,
        default: 0,
    },

    // Accuracy percentage
    accuracy: {
        type: Number,
        default: 0,
    },

    // Total time taken for test in minutes
    totalTimeTaken: {
        type: Number,
        default: 0,
    },

    // When the test was attempted
    attemptedAt: {
        type: Date,
        default: Date.now,
    },
});

// Index for faster queries
testResultSchema.index({ userId: 1, testId: 1 });

module.exports = mongoose.model('TestResult', testResultSchema);
