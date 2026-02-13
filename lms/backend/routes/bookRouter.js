const express = require('express');
const Book = require('../models/Book');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
    try {
        const books = await Book.find();
        res.status(200).json({ books });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.get('/:id', authMiddleware, async (req, res) => {
    try {
        const book = await Book.findById(req.params.id);
        if (!book) {
            return res.status(404).json({ message: 'Book not found' });
        }
        res.status(200).json({ book });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.post('/', authMiddleware, async (req, res) => {
    try {

        const user = req.user;
        if (user.userType !== 'LIBRARIAN') {
            return res.status(403).json({ message: 'Access denied. Only librarians can add books.' });
        }

        const { title, description, author, price, quantity, imageUrl, pdfUrl, category } = req.body;

        const newBook = {
            title,
            author,
            description,
            price,
            quantity,
            imageUrl,
            pdfUrl,
            category
        };

        const book = new Book(newBook);
        await book.save();
        res.status(201).json({ message: 'Book added successfully', book });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.put('/:id', authMiddleware, async (req, res) => {
    try {

        const user = req.user;
        if (user.userType !== 'LIBRARIAN') {
            return res.status(403).json({ message: 'Access denied. Only librarians can update books.' });
        }

        const { title, description, author, price, quantity, imageUrl, pdfUrl, category, status } = req.body;

        const book = await Book.findByIdAndUpdate(
            req.params.id,
            {
                title,
                description,
                author,
                price,
                quantity,
                imageUrl,
                pdfUrl,
                category,
                status
            },
            { new: true }
        );

        if (!book) {
            return res.status(404).json({ message: 'Book not found' });
        }

        res.status(200).json({ message: 'Book updated successfully', book });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.delete('/:id', authMiddleware, async (req, res) => {
    try {

        const user = req.user;
        if (user.userType !== 'LIBRARIAN') {
            return res.status(403).json({ message: 'Access denied. Only librarians can delete books.' });
        }

        const book = await Book.findByIdAndDelete(req.params.id);
        if (!book) {
            return res.status(404).json({ message: 'Book not found' });
        }
        res.status(200).json({ message: 'Book deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;