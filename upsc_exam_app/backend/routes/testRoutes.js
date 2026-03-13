// Test Routes
// Handles test series and test submissions

const express = require('express');
const router = express.Router();
const {
    getTestsByCourse,
    getTest,
    submitTest,
    getTestResults,
    createTest,
    getAllTests,
    getMyTests,
    updateTest,
    deleteTest,
    addQuestion,
    updateQuestion,
    deleteQuestion,
    getTestHistory,
    getTestResult,
} = require('../controllers/testController');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// Standalone test series routes (not tied to courses)
// @route   GET /api/test/all
// @desc    Get all standalone tests
// @access  Public
router.get('/all', getAllTests);

// @route   GET /api/test/my-tests
// @desc    Get educator's tests
// @access  Private/Educator
router.get('/my-tests', protect, restrictTo('educator'), getMyTests);

// @route   GET /api/test/history
// @desc    Get user's test history
// @access  Private
router.get('/history', protect, getTestHistory);

// @route   GET /api/test/result/:resultId
// @desc    Get detailed test result
// @access  Private
router.get('/result/:resultId', protect, getTestResult);

// Question management routes
// @route   POST /api/test/:id/question
// @desc    Add question to test
// @access  Private/Educator
router.post('/:id/question', protect, restrictTo('educator'), addQuestion);

// @route   PUT /api/test/:testId/question/:questionId
// @desc    Update question in test
// @access  Private/Educator
router.put('/:testId/question/:questionId', protect, restrictTo('educator'), updateQuestion);

// @route   DELETE /api/test/:testId/question/:questionId
// @desc    Delete question from test
// @access  Private/Educator
router.delete('/:testId/question/:questionId', protect, restrictTo('educator'), deleteQuestion);

// Test CRUD routes
// @route   POST /api/test/create
// @desc    Create new test with questions (Educator only)
// @access  Private/Educator
router.post('/create', protect, restrictTo('educator'), createTest);

// @route   PUT /api/test/:id
// @desc    Update test
// @access  Private/Educator
router.put('/:id', protect, restrictTo('educator'), updateTest);

// @route   DELETE /api/test/:id
// @desc    Delete test
// @access  Private/Educator
router.delete('/:id', protect, restrictTo('educator'), deleteTest);

// Course-specific test routes
// @route   GET /api/test/:courseId
// @desc    Get all tests for a specific course
// @access  Private
router.get('/:courseId', protect, getTestsByCourse);

// @route   GET /api/test/test/:id
// @desc    Get single test with questions
// @access  Private
router.get('/test/:id', protect, getTest);

// @route   POST /api/test/submit
// @desc    Submit test and get results
// @access  Private
router.post('/submit', protect, submitTest);

// @route   GET /api/test/results/:testId
// @desc    Get test results for logged in user
// @access  Private
router.get('/results/:testId', protect, getTestResults);

module.exports = router;
