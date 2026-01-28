const express = require('express');
const Employee = require('../models/Employee');
const router = express.Router();

router.get('/', async (request, response) => {
    try {
        const employees = await Employee.find({});
        response.json(employees);
    } catch (error) {
        response.status(500).json({ message: "Error fetching employees", error: error.message });
    }
});

router.get('/:id', async (request, response) => {
    try {
        const employee = await Employee.findById(request.params.id);
        response.json(employee);
    } catch (error) {
        response.status(500).json({ message: "Error fetching employee", error: error.message });
    }
});

router.post('/', async (request, response) => {
    try {
        const { name, email, role, department, salary } = request.body;
        const newEmployee = {
            name,
            email,
            role,
            department,
            salary
        };
        const e = new Employee(newEmployee);
        await e.save();
        response.status(201).json({ message: "Employee created successfully" });
    } catch (error) {
        response.status(500).json({ message: "Error creating employee", error: error.message });
    }
});

router.put('/:id', async (request, response) => {
    try {
        const employee = await Employee.findByIdAndUpdate(request.params.id, request.body, { new: true });
        if (!employee) {
            return response.status(404).json({ message: "Employee not found" });
        }
        response.status(200).json({ message: "Employee updated successfully" });
    } catch (error) {
        response.status(500).json({ message: "Error updating employee", error: error.message });
    }
});

router.delete('/:id', async (request, response) => {
    try {
        const employee = await Employee.findByIdAndDelete(request.params.id);
        if (!employee) {
            return response.status(404).json({ message: "Employee not found" });
        }
        response.status(200).json({ message: "Employee deleted successfully" });
    } catch (error) {
        response.status(500).json({ message: "Error deleting employee", error: error.message });
    }
});

module.exports = router;