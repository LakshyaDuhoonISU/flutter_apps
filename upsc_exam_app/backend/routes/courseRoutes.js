// Course Routes
// Handles all course-related endpoints

const express = require('express');
const router = express.Router();
const {
    getCourses,
    getCourse,
    createCourse,
    enrollCourse,
    getMyCourses,
    getMySchedule,
    markClassCompleted,
    bookmarkClass,
    unbookmarkClass,
    getBookmarkedClasses,
    getClassNotes,
    addClassNote,
    updateClassNote,
    deleteClassNote,
    updateCourse,
    deleteCourse,
    getEducatorCourses,
    createTopic,
    updateTopic,
    deleteTopic,
    createClass,
    updateClass,
    deleteClass,
} = require('../controllers/courseController');
const { protect } = require('../middleware/authMiddleware');
const { optionalProtect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   GET /api/courses
// @desc    Get all courses (with optional filters)
// @access  Public
router.get('/', getCourses);

// @route   GET /api/courses/my-courses
// @desc    Get enrolled courses for logged in user
// @access  Private
router.get('/my-courses', protect, getMyCourses);

// @route   GET /api/courses/my-schedule
// @desc    Get class schedule for logged in user's enrolled courses
// @access  Private
router.get('/my-schedule', protect, getMySchedule);

// @route   GET /api/courses/educator/my-courses
// @desc    Get courses created by logged in educator
// @access  Private/Educator
router.get('/educator/my-courses', protect, restrictTo('educator'), getEducatorCourses);

// @route   GET /api/courses/bookmarks
// @desc    Get all bookmarked classes
// @access  Private
router.get('/bookmarks', protect, getBookmarkedClasses);

// @route   GET /api/courses/:id
// @desc    Get single course with topics and classes
// @access  Public (optionally authenticated for enrollment status)
router.get('/:id', optionalProtect, getCourse);

// @route   POST /api/courses
// @desc    Create new course (Educator only)
// @access  Private/Educator
router.post('/', protect, restrictTo('educator'), createCourse);

// @route   PUT /api/courses/:id
// @desc    Update course (Creator only)
// @access  Private/Educator
router.put('/:id', protect, restrictTo('educator'), updateCourse);

// @route   DELETE /api/courses/:id
// @desc    Delete course (Creator only)
// @access  Private/Educator
router.delete('/:id', protect, restrictTo('educator'), deleteCourse);

// @route   POST /api/courses/:id/enroll
// @desc    Enroll in a course
// @access  Private
router.post('/:id/enroll', protect, enrollCourse);

// @route   POST /api/courses/classes/:classId/complete
// @desc    Mark class as completed
// @access  Private
router.post('/classes/:classId/complete', protect, markClassCompleted);

// @route   POST /api/courses/classes/:classId/bookmark
// @desc    Bookmark a class
// @access  Private
router.post('/classes/:classId/bookmark', protect, bookmarkClass);

// @route   DELETE /api/courses/classes/:classId/bookmark
// @desc    Remove bookmark from a class
// @access  Private
router.delete('/classes/:classId/bookmark', protect, unbookmarkClass);

// Notes routes
// @route   GET /api/courses/classes/:classId/notes
// @desc    Get all notes for a class
// @access  Private
router.get('/classes/:classId/notes', protect, getClassNotes);

// @route   POST /api/courses/classes/:classId/notes
// @desc    Add a note to a class
// @access  Private
router.post('/classes/:classId/notes', protect, addClassNote);

// @route   PUT /api/courses/classes/:classId/notes/:noteId
// @desc    Update a note
// @access  Private
router.put('/classes/:classId/notes/:noteId', protect, updateClassNote);

// @route   DELETE /api/courses/classes/:classId/notes/:noteId
// @desc    Delete a note
// @access  Private
router.delete('/classes/:classId/notes/:noteId', protect, deleteClassNote);

// Topic routes
// @route   POST /api/courses/:courseId/topics
// @desc    Create topic in a course (Creator only)
// @access  Private/Educator
router.post('/:courseId/topics', protect, restrictTo('educator'), createTopic);

// @route   PUT /api/courses/:courseId/topics/:topicId
// @desc    Update topic (Creator only)
// @access  Private/Educator
router.put('/:courseId/topics/:topicId', protect, restrictTo('educator'), updateTopic);

// @route   DELETE /api/courses/:courseId/topics/:topicId
// @desc    Delete topic (Creator only)
// @access  Private/Educator
router.delete('/:courseId/topics/:topicId', protect, restrictTo('educator'), deleteTopic);

// Class routes
// @route   POST /api/courses/:courseId/topics/:topicId/classes
// @desc    Create class/video in a topic (Creator only)
// @access  Private/Educator
router.post('/:courseId/topics/:topicId/classes', protect, restrictTo('educator'), createClass);

// @route   PUT /api/courses/:courseId/classes/:classId
// @desc    Update class/video (Creator only)
// @access  Private/Educator
router.put('/:courseId/classes/:classId', protect, restrictTo('educator'), updateClass);

// @route   DELETE /api/courses/:courseId/classes/:classId
// @desc    Delete class/video (Creator only)
// @access  Private/Educator
router.delete('/:courseId/classes/:classId', protect, restrictTo('educator'), deleteClass);

module.exports = router;
