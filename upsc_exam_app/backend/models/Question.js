// Question Model
// Stores individual questions for tests

const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
    // Test this question belongs to
    testId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Test',
        required: true,
    },

    // Topic this question is related to
    topicId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Topic',
    },

    // Question text
    question: {
        type: String,
        required: [true, 'Please add a question'],
    },

    // Answer options (array of 4 options)
    options: [{
        type: String,
        required: true,
    }],

    // Correct answer (index: 0, 1, 2, or 3)
    correctAnswer: {
        type: Number,
        required: [true, 'Please add correct answer index'],
        min: 0,
        max: 3,
    },

    // Explanation for the answer
    explanation: {
        type: String,
        default: '',
    },

    // Question difficulty level
    difficulty: {
        type: String,
        enum: ['Easy', 'Medium', 'Hard'],
        default: 'Medium',
    },

    // Marks for this question
    marks: {
        type: Number,
        default: 1,
    },

    // Previous year question?
    isPreviousYear: {
        type: Boolean,
        default: false,
    },

    // Year it appeared in exam (if previous year question)
    year: {
        type: Number,
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('Question', questionSchema);
