// Live Chat Model
// Stores chat messages for live classes

const mongoose = require('mongoose');

const liveChatSchema = new mongoose.Schema({
    classId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
        required: true,
        index: true,
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    userName: {
        type: String,
        required: true,
    },
    userRole: {
        type: String,
        enum: ['student', 'educator'],
        required: true,
    },
    message: {
        type: String,
        required: true,
        maxlength: 500,
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
liveChatSchema.index({ classId: 1, createdAt: -1 });

// Auto-delete chats after 24 hours of class end
liveChatSchema.index({ createdAt: 1 }, { expireAfterSeconds: 86400 });

module.exports = mongoose.model('LiveChat', liveChatSchema);
