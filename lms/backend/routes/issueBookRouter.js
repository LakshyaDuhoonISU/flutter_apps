const express = require('express');
const Book = require('../models/Book');
const User = require('../models/User');
const issueBook = require('../models/issueBook');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/issue-book', authMiddleware, async (req, res) => {
    try {

        const user = req.user;
        if (user.userType !== 'LIBRARIAN') {
            return res.status(403).json({ message: 'Access denied. Only librarians can issue books.' });
        }

        const { bookId, bookName, studentId, studentName, issueDate, returnDate } = req.body;

        const book = await Book.findById(bookId);
        if (!book) {
            return res.status(404).json({ message: 'Book not found' });
        }

        const student = await User.findById(studentId);
        if (!student) {
            return res.status(404).json({ message: 'Student not found' });
        }

        if (book.title !== bookName) {
            return res.status(400).json({ message: 'Book name does not match' });
        }

        if (student.name !== studentName) {
            return res.status(400).json({ message: 'Student name does not match' });
        }

        if (book.quantity <= 0) {
            return res.status(400).json({ message: 'Book is currently unavailable' });
        }

        const newIssue = {
            bookId,
            bookName,
            studentId,
            studentName,
            issueDate,
            returnDate,
            status: 'ISSUED'
        };

        const issueBookRecord = new issueBook(newIssue);
        await issueBookRecord.save();

        book.quantity -= 1;
        if (book.quantity === 0) {
            book.status = 'UNAVAILABLE';
        }

        await book.save();
        res.status(200).json({ message: 'Book issued successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.post('/return-book/:id', authMiddleware, async (req, res) => {
    try {

        const user = req.user;
        if (user.userType !== 'LIBRARIAN') {
            return res.status(403).json({ message: 'Access denied. Only librarians can return books.' });
        }

        const issueBookRecord = await issueBook.findById(req.params.id);
        if (!issueBookRecord) {
            return res.status(404).json({ message: 'Issue book record not found' });
        }

        if (issueBookRecord.status === 'RETURNED') {
            return res.status(400).json({ message: 'Book has already been returned' });
        }

        issueBookRecord.status = 'RETURNED';
        await issueBookRecord.save();

        const book = await Book.findById(issueBookRecord.bookId);

        book.quantity += 1;
        if (book.quantity > 0) {
            book.status = 'AVAILABLE';
        }
        await book.save();
        res.status(200).json({ message: 'Book returned successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;