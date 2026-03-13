// Live Poll Model
// Stores polls created by educators during live classes

const mongoose = require('mongoose');

const livePollSchema = new mongoose.Schema({
    classId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
        required: true,
        index: true,
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    question: {
        type: String,
        required: true,
        maxlength: 200,
    },
    options: [{
        text: {
            type: String,
            required: true,
        },
        votes: {
            type: Number,
            default: 0,
        },
    }],
    voters: [{
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        selectedOption: {
            type: Number,
            required: true,
        },
        votedAt: {
            type: Date,
            default: Date.now,
        },
    }],
    durationSeconds: {
        type: Number,
        required: true,
        min: 10,
        max: 300, // 5 minutes max
    },
    startsAt: {
        type: Date,
        default: Date.now,
    },
    endsAt: {
        type: Date,
        required: true,
    },
    isActive: {
        type: Boolean,
        default: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Pre-save hook to calculate endsAt
livePollSchema.pre('save', function (next) {
    if (this.isNew) {
        this.endsAt = new Date(this.startsAt.getTime() + this.durationSeconds * 1000);
    }
    next();
});

// Index for efficient queries
livePollSchema.index({ classId: 1, createdAt: -1 });
livePollSchema.index({ endsAt: 1 });

module.exports = mongoose.model('LivePoll', livePollSchema);
