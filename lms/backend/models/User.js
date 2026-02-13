const mongoose = require('mongoose');

const userSchema = {
    name: {
        type: String,
        required: true
    },
    username: {
        type: String,
        required: true,
        unique: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    userType: {
        type: String,
        enum: ['LIBRARIAN', 'STUDENT'],
        default: 'STUDENT'
    },
    password: {
        type: String,
        required: true
    }
};

const User = new mongoose.model('User', userSchema);

module.exports = User;