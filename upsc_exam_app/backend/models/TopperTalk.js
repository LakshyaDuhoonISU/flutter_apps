// TopperTalk Model
// Stores videos/sessions from UPSC toppers

const mongoose = require('mongoose');

const topperTalkSchema = new mongoose.Schema({
    // Title of the topper talk session
    title: {
        type: String,
        required: [true, 'Please add a title'],
        trim: true,
    },

    // Name of the topper
    topperName: {
        type: String,
        required: [true, 'Please add topper name'],
    },

    // Rank achieved by the topper
    rank: {
        type: Number,
        required: [true, 'Please add rank'],
    },

    // Year of exam
    year: {
        type: Number,
        required: [true, 'Please add year'],
    },

    // Optional field of the topper
    optional: {
        type: String,
        default: '',
    },

    // Video URL
    videoUrl: {
        type: String,
        required: [true, 'Please add video URL'],
    },

    // Thumbnail URL
    thumbnail: {
        type: String,
        default: '',
    },

    // Duration in minutes
    durationMinutes: {
        type: Number,
        default: 0,
    },

    // Is this session free to access?
    isFree: {
        type: Boolean,
        default: true,
    },

    // Description of the session
    description: {
        type: String,
        default: '',
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('TopperTalk', topperTalkSchema);
