// PYQSet Model
// Stores Previous Year Question sets with multiple questions

const mongoose = require('mongoose');

const pyqSetSchema = new mongoose.Schema({
    // Title of the PYQ set (e.g., "2024 Polity PYQ")
    title: {
        type: String,
        required: [true, 'Please add a title'],
        trim: true,
    },

    // Year of the questions
    year: {
        type: Number,
        required: [true, 'Please specify the year'],
    },

    // Subject/Category (Polity, History, Geography, etc.)
    subject: {
        type: String,
        required: [true, 'Please specify the subject'],
        trim: true,
    },

    // Description of the PYQ set
    description: {
        type: String,
        default: '',
    },

    // Course ID this PYQ set belongs to
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
        required: [true, 'Please specify the course'],
    },

    // Array of questions in this PYQ set
    questions: [{
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
        difficulty: {
            type: String,
            enum: ['Easy', 'Medium', 'Hard'],
            default: 'Medium',
        },
        marks: {
            type: Number,
            default: 1,
        },
    }],

    // Total questions in this set
    totalQuestions: {
        type: Number,
        default: 0,
    },

    // Total marks for this set
    totalMarks: {
        type: Number,
        default: 0,
    },

    // Creator (educator ID)
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Calculate total questions and marks before saving
pyqSetSchema.pre('save', function (next) {
    this.totalQuestions = this.questions.length;
    this.totalMarks = this.questions.reduce((sum, q) => sum + (q.marks || 1), 0);
    next();
});

// Index for faster queries
pyqSetSchema.index({ courseId: 1 });
pyqSetSchema.index({ year: -1 });
pyqSetSchema.index({ subject: 1 });

module.exports = mongoose.model('PYQSet', pyqSetSchema);
