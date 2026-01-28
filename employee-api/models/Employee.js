const mongoose = require('mongoose');

const employeeSchema = {
    name: {
        type: String,
        required: true,
    },
    email: {
        type: String,
        required: true,
        unique: true,
    },
    role: {
        type: String,
        required: true,
    },
    department: {
        type: String,
        required: true,
    },
    salary: {
        type: String,
        required: true,
    }
};

const Employee = new mongoose.model('Employee', employeeSchema);
module.exports = Employee;