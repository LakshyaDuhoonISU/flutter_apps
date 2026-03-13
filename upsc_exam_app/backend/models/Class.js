// Class Model
// Represents individual classes (live or recorded) for a topic

const mongoose = require('mongoose');

const classSchema = new mongoose.Schema({
    // Course this class belongs to
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
        required: true,
    },

    // Topic this class covers
    topicId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Topic',
        required: true,
    },

    // Class title
    title: {
        type: String,
        required: [true, 'Please add a class title'],
        trim: true,
    },

    // Class type: live or recorded
    type: {
        type: String,
        enum: ['live', 'recorded'],
        required: true,
    },

    // When the class is scheduled (for live classes)
    scheduledAt: {
        type: Date,
    },

    // Video URL (for recorded classes or live class recordings)
    videoUrl: {
        type: String,
        default: '',
    },

    // Class duration in minutes
    durationMinutes: {
        type: Number,
        required: true,
        default: 60,
    },

    // Is the class completed?
    isCompleted: {
        type: Boolean,
        default: false,
    },

    // Class description
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

module.exports = mongoose.model('Class', classSchema);
