// User Model
// Stores information about students and educators

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    // User's full name
    name: {
        type: String,
        required: [true, 'Please add a name'],
        trim: true,
    },

    // Email address (used for login)
    email: {
        type: String,
        required: [true, 'Please add an email'],
        unique: true,
        lowercase: true,
        match: [
            /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
            'Please add a valid email',
        ],
    },

    // Password (will be hashed before saving)
    password: {
        type: String,
        required: [true, 'Please add a password'],
        minlength: 6,
        select: false, // Don't return password by default in queries
    },

    // User role: student or educator
    role: {
        type: String,
        enum: ['student', 'educator'],
        default: 'student',
    },

    // Subscription type for students
    subscriptionType: {
        type: String,
        enum: ['plus', 'individual', 'test-series', 'none'],
        default: 'none',
    },

    // Courses the student is enrolled in
    enrolledCourses: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
    }],

    // Classes completed by the student
    completedClasses: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
    }],

    // Classes bookmarked by the student
    bookmarkedClasses: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
    }],

    // Notes for bookmarked classes
    classNotes: [{
        classId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Class',
            required: true,
        },
        content: {
            type: String,
            required: true,
        },
        isHighlighted: {
            type: Boolean,
            default: false,
        },
        createdAt: {
            type: Date,
            default: Date.now,
        },
        updatedAt: {
            type: Date,
            default: Date.now,
        },
    }],

    // Experience in years (for educators)
    experience: {
        type: Number,
        default: 0,
        min: 0,
    },

    // Account creation timestamp
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

// Hash password before saving to database
userSchema.pre('save', async function (next) {
    // Only hash the password if it has been modified (or is new)
    if (!this.isModified('password')) {
        next();
    }

    // Generate salt and hash password
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare entered password with hashed password
userSchema.methods.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
