// CurrentAffairs Model
// Stores daily current affairs with quiz

const mongoose = require('mongoose');

const currentAffairsSchema = new mongoose.Schema({
    // Date of the current affairs
    date: {
        type: Date,
        required: true,
        unique: true,
    },

    // Title of the current affairs
    title: {
        type: String,
        required: [true, 'Please add a title'],
        trim: true,
    },

    // Summary/content of current affairs
    summary: {
        type: String,
        required: [true, 'Please add summary'],
    },

    // Array of quiz questions
    quiz: [{
        question: {
            type: String,
            required: true,
        },
        options: [{
            type: String,
            required: true,
        }],
        correctAnswer: {
            type: Number,
            required: true,
            min: 0,
            max: 3,
        },
        explanation: {
            type: String,
            default: '',
        },
    }],

    // Category (National, International, Economy, etc.)
    category: {
        type: String,
        default: 'General',
    },

    // Image URL for the current affairs
    imageUrl: {
        type: String,
        default: '',
    },

    // Creator (educator ID)
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Index for faster date-based queries
currentAffairsSchema.index({ date: -1 });

module.exports = mongoose.model('CurrentAffairs', currentAffairsSchema);
