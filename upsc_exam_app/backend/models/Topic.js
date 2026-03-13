// Topic Model
// Represents topics/chapters within a course

const mongoose = require('mongoose');

const topicSchema = new mongoose.Schema({
    // Course this topic belongs to
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
        required: true,
    },

    // Topic title
    title: {
        type: String,
        required: [true, 'Please add a topic title'],
        trim: true,
    },

    // Topic description
    description: {
        type: String,
        required: [true, 'Please add a topic description'],
    },

    // Order of topic in course syllabus
    orderIndex: {
        type: Number,
        required: true,
        default: 0,
    },

    // Estimated hours to complete
    estimatedHours: {
        type: Number,
        default: 0,
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Index to sort topics by order within a course
topicSchema.index({ courseId: 1, orderIndex: 1 });

module.exports = mongoose.model('Topic', topicSchema);
