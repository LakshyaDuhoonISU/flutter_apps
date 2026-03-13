// Note Model
// Stores personal notes created by students

const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
    // Student who created the note
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Course this note is related to
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
    },

    // Topic this note is related to
    topicId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Topic',
    },

    // Note title
    title: {
        type: String,
        required: [true, 'Please add a note title'],
        trim: true,
    },

    // Note content (can include HTML for formatting)
    content: {
        type: String,
        required: [true, 'Please add note content'],
    },

    // Is this note bookmarked?
    bookmarked: {
        type: Boolean,
        default: false,
    },

    // Tags for organizing notes
    tags: [{
        type: String,
    }],

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },

    // Last updated timestamp
    updatedAt: {
        type: Date,
        default: Date.now,
    },
});

// Update updatedAt timestamp before saving
noteSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('Note', noteSchema);
