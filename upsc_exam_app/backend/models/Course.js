// Course Model
// Represents individual courses created by educators

const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
    // Course title
    title: {
        type: String,
        required: [true, 'Please add a course title'],
        trim: true,
    },

    // Subject (e.g., History, Geography, Polity)
    subject: {
        type: String,
        required: [true, 'Please add a subject'],
        trim: true,
    },

    // Course description
    description: {
        type: String,
        required: [true, 'Please add a description'],
    },

    // ID of the educator who created this course
    educatorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Course price in INR
    price: {
        type: Number,
        required: [true, 'Please add a price'],
        min: 0,
    },

    // Is this course included in Plus subscription?
    isPlusIncluded: {
        type: Boolean,
        default: true,
    },

    // Array of topic IDs covered in this course
    syllabusTopics: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Topic',
    }],

    // Number of students enrolled
    enrolledStudents: {
        type: Number,
        default: 0,
    },

    // Thumbnail image URL
    thumbnail: {
        type: String,
        default: '',
    },

    // Course creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('Course', courseSchema);
