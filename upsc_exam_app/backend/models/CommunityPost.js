// CommunityPost Model
// Represents posts in the community discussion forum

const mongoose = require('mongoose');

const communityPostSchema = new mongoose.Schema({
    // Post title
    title: {
        type: String,
        required: [true, 'Please add a post title'],
        trim: true,
    },

    // Post content
    content: {
        type: String,
        required: [true, 'Please add post content'],
    },

    // User who created the post
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Category/topic of the post
    category: {
        type: String,
        default: 'General Discussion',
    },

    // Array of replies to this post
    replies: [{
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        message: {
            type: String,
            required: true,
        },
        createdAt: {
            type: Date,
            default: Date.now,
        },
    }],

    // Number of upvotes
    upvotes: {
        type: Number,
        default: 0,
    },

    // Users who upvoted this post
    upvotedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    }],

    // Is this post pinned by moderator?
    isPinned: {
        type: Boolean,
        default: false,
    },

    // Is this post locked? (no more replies)
    isLocked: {
        type: Boolean,
        default: false,
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Index for faster queries
communityPostSchema.index({ createdAt: -1 });
communityPostSchema.index({ isPinned: -1, createdAt: -1 });

module.exports = mongoose.model('CommunityPost', communityPostSchema);
