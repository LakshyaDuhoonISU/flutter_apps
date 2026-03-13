// Live Doubt Model
// Stores doubts/questions raised by students during live classes

const mongoose = require('mongoose');

const liveDoubtSchema = new mongoose.Schema({
    classId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
        required: true,
        index: true,
    },
    studentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    studentName: {
        type: String,
        required: true,
    },
    question: {
        type: String,
        required: true,
        maxlength: 500,
    },
    answer: {
        type: String,
        maxlength: 1000,
    },
    answeredBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    answeredAt: {
        type: Date,
    },
    status: {
        type: String,
        enum: ['pending', 'answered', 'deleted'],
        default: 'pending',
    },
    isDeleted: {
        type: Boolean,
        default: false,
    },
    deletedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Index for efficient queries
liveDoubtSchema.index({ classId: 1, status: 1, createdAt: -1 });

// Auto-delete doubts after 7 days
liveDoubtSchema.index({ createdAt: 1 }, { expireAfterSeconds: 604800 });

module.exports = mongoose.model('LiveDoubt', liveDoubtSchema);
