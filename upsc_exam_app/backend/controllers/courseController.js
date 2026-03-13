// Course Controller
// Handles course-related operations

const Course = require('../models/Course');
const Topic = require('../models/Topic');
const Class = require('../models/Class');
const User = require('../models/User');

/**
 * @desc    Get all courses
 * @route   GET /api/courses
 * @access  Public
 */
const getCourses = async (req, res) => {
    try {
        // Query parameters for filtering
        const { subject, isPlusIncluded } = req.query;

        let query = {};

        // Filter by subject if provided
        if (subject) {
            query.subject = subject;
        }

        // Filter by plus subscription if provided
        if (isPlusIncluded !== undefined) {
            query.isPlusIncluded = isPlusIncluded === 'true';
        }

        // Get all courses with educator details
        const courses = await Course.find(query)
            .populate('educatorId', 'name email')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: courses.length,
            data: courses,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching courses',
            error: error.message,
        });
    }
};

/**
 * @desc    Get single course by ID with topics and classes
 * @route   GET /api/courses/:id
 * @access  Public
 */
const getCourse = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id)
            .populate('educatorId', 'name email')
            .populate('syllabusTopics');

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Get all topics for this course
        const topics = await Topic.find({ courseId: course._id })
            .sort({ orderIndex: 1 });

        // Get all classes for this course
        const classes = await Class.find({ courseId: course._id })
            .populate('topicId', 'title')
            .sort({ scheduledAt: 1 });

        // Check if user is enrolled (if logged in)
        let isEnrolled = false;
        let completedClassIds = [];
        if (req.user) {
            const user = await User.findById(req.user._id);
            isEnrolled = user.enrolledCourses.some(
                courseId => courseId.toString() === course._id.toString()
            );
            completedClassIds = user.completedClasses.map(id => id.toString());
        }

        res.status(200).json({
            success: true,
            data: {
                course,
                topics,
                classes,
                isEnrolled,
                completedClassIds,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching course',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new course (Educator only)
 * @route   POST /api/courses
 * @access  Private/Educator
 */
const createCourse = async (req, res) => {
    try {
        const { title, subject, description, price, isPlusIncluded } = req.body;

        // Validate input
        if (!title || !subject || !description || price === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields',
            });
        }

        // Create course with educator ID from authenticated user
        const course = await Course.create({
            title,
            subject,
            description,
            price,
            isPlusIncluded: isPlusIncluded !== undefined ? isPlusIncluded : true,
            educatorId: req.user._id,
        });

        res.status(201).json({
            success: true,
            message: 'Course created successfully',
            data: course,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating course',
            error: error.message,
        });
    }
};

/**
 * @desc    Enroll in a course
 * @route   POST /api/courses/:id/enroll
 * @access  Private/Student
 */
const enrollCourse = async (req, res) => {
    try {
        const courseId = req.params.id;
        const userId = req.user._id;

        // Check if course exists
        const course = await Course.findById(courseId);
        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if already enrolled
        const user = await User.findById(userId);
        if (user.enrolledCourses.includes(courseId)) {
            return res.status(400).json({
                success: false,
                message: 'Already enrolled in this course',
            });
        }

        // Check individual plan enrollment limit
        if (user.subscriptionType === 'individual' && user.enrolledCourses.length >= 1) {
            return res.status(400).json({
                success: false,
                message: 'Individual plan allows enrollment in only one course. Please upgrade to Plus plan to enroll in multiple courses.',
            });
        }

        // Add course to user's enrolled courses
        user.enrolledCourses.push(courseId);
        await user.save();

        // Increment enrolled students count
        course.enrolledStudents += 1;
        await course.save();

        res.status(200).json({
            success: true,
            message: 'Successfully enrolled in course',
            data: {
                courseId: course._id,
                courseTitle: course.title,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while enrolling',
            error: error.message,
        });
    }
};

/**
 * @desc    Get enrolled courses for logged in user
 * @route   GET /api/courses/my-courses
 * @access  Private
 */
const getMyCourses = async (req, res) => {
    try {
        const user = await User.findById(req.user._id)
            .populate({
                path: 'enrolledCourses',
                populate: {
                    path: 'educatorId',
                    select: 'name email',
                },
            });

        res.status(200).json({
            success: true,
            count: user.enrolledCourses.length,
            data: user.enrolledCourses,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching enrolled courses',
            error: error.message,
        });
    }
};

/**
 * @desc    Update course (Creator only)
 * @route   PUT /api/courses/:id
 * @access  Private/Educator/Creator
 */
const updateCourse = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this course',
            });
        }

        const { title, subject, description, price, isPlusIncluded, thumbnail } = req.body;

        // Update fields
        if (title) course.title = title;
        if (subject) course.subject = subject;
        if (description) course.description = description;
        if (price !== undefined) course.price = price;
        if (isPlusIncluded !== undefined) course.isPlusIncluded = isPlusIncluded;
        if (thumbnail !== undefined) course.thumbnail = thumbnail;

        await course.save();

        res.status(200).json({
            success: true,
            message: 'Course updated successfully',
            data: course,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating course',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete course (Creator only)
 * @route   DELETE /api/courses/:id
 * @access  Private/Educator/Creator
 */
const deleteCourse = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this course',
            });
        }

        // Delete all associated topics and classes
        await Topic.deleteMany({ courseId: course._id });
        await Class.deleteMany({ courseId: course._id });

        // Delete the course
        await Course.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Course and all associated content deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting course',
            error: error.message,
        });
    }
};

/**
 * @desc    Get courses created by logged in educator
 * @route   GET /api/courses/educator/my-courses
 * @access  Private/Educator
 */
const getEducatorCourses = async (req, res) => {
    try {
        const courses = await Course.find({ educatorId: req.user._id })
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: courses.length,
            data: courses,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching educator courses',
            error: error.message,
        });
    }
};

/**
 * @desc    Create topic in a course (Course creator only)
 * @route   POST /api/courses/:courseId/topics
 * @access  Private/Educator/Creator
 */
const createTopic = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to add topics to this course',
            });
        }

        const { title, description, orderIndex, estimatedHours } = req.body;

        if (!title || !description) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title and description',
            });
        }

        const topic = await Topic.create({
            courseId: course._id,
            title,
            description,
            orderIndex: orderIndex || 0,
            estimatedHours: estimatedHours || 0,
        });

        // Add topic to course's syllabusTopics
        course.syllabusTopics.push(topic._id);
        await course.save();

        res.status(201).json({
            success: true,
            message: 'Topic created successfully',
            data: topic,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating topic',
            error: error.message,
        });
    }
};

/**
 * @desc    Update topic (Course creator only)
 * @route   PUT /api/courses/:courseId/topics/:topicId
 * @access  Private/Educator/Creator
 */
const updateTopic = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update topics in this course',
            });
        }

        const topic = await Topic.findById(req.params.topicId);

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: 'Topic not found',
            });
        }

        const { title, description, orderIndex, estimatedHours } = req.body;

        if (title) topic.title = title;
        if (description) topic.description = description;
        if (orderIndex !== undefined) topic.orderIndex = orderIndex;
        if (estimatedHours !== undefined) topic.estimatedHours = estimatedHours;

        await topic.save();

        res.status(200).json({
            success: true,
            message: 'Topic updated successfully',
            data: topic,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating topic',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete topic (Course creator only)
 * @route   DELETE /api/courses/:courseId/topics/:topicId
 * @access  Private/Educator/Creator
 */
const deleteTopic = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete topics in this course',
            });
        }

        const topic = await Topic.findById(req.params.topicId);

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: 'Topic not found',
            });
        }

        // Delete all classes associated with this topic
        await Class.deleteMany({ topicId: topic._id });

        // Remove topic from course's syllabusTopics
        course.syllabusTopics = course.syllabusTopics.filter(
            id => id.toString() !== topic._id.toString()
        );
        await course.save();

        // Delete the topic
        await Topic.findByIdAndDelete(req.params.topicId);

        res.status(200).json({
            success: true,
            message: 'Topic and all associated classes deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting topic',
            error: error.message,
        });
    }
};

/**
 * @desc    Create class/video in a topic (Course creator only)
 * @route   POST /api/courses/:courseId/topics/:topicId/classes
 * @access  Private/Educator/Creator
 */
const createClass = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to add classes to this course',
            });
        }

        const topic = await Topic.findById(req.params.topicId);

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: 'Topic not found',
            });
        }

        const { title, type, scheduledAt, videoUrl, durationMinutes, description, isCompleted } = req.body;

        if (!title || !type) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title and type',
            });
        }

        const classData = await Class.create({
            courseId: course._id,
            topicId: topic._id,
            title,
            type,
            scheduledAt: scheduledAt || null,
            videoUrl: videoUrl || '',
            durationMinutes: durationMinutes || 60,
            description: description || '',
            isCompleted: isCompleted || false,
        });

        res.status(201).json({
            success: true,
            message: 'Class created successfully',
            data: classData,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating class',
            error: error.message,
        });
    }
};

/**
 * @desc    Update class/video (Course creator only)
 * @route   PUT /api/courses/:courseId/classes/:classId
 * @access  Private/Educator/Creator
 */
const updateClass = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update classes in this course',
            });
        }

        const classData = await Class.findById(req.params.classId);

        if (!classData) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        const { title, type, scheduledAt, videoUrl, durationMinutes, description, isCompleted } = req.body;

        if (title) classData.title = title;
        if (type) classData.type = type;
        if (scheduledAt !== undefined) classData.scheduledAt = scheduledAt;
        if (videoUrl !== undefined) classData.videoUrl = videoUrl;
        if (durationMinutes !== undefined) classData.durationMinutes = durationMinutes;
        if (description !== undefined) classData.description = description;
        if (isCompleted !== undefined) classData.isCompleted = isCompleted;

        await classData.save();

        res.status(200).json({
            success: true,
            message: 'Class updated successfully',
            data: classData,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating class',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete class/video (Course creator only)
 * @route   DELETE /api/courses/:courseId/classes/:classId
 * @access  Private/Educator/Creator
 */
const deleteClass = async (req, res) => {
    try {
        const course = await Course.findById(req.params.courseId);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found',
            });
        }

        // Check if user is the course creator
        if (course.educatorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete classes in this course',
            });
        }

        const classData = await Class.findById(req.params.classId);

        if (!classData) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        await Class.findByIdAndDelete(req.params.classId);

        res.status(200).json({
            success: true,
            message: 'Class deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting class',
            error: error.message,
        });
    }
};

/**
 * @desc    Get class schedule for logged in user's enrolled courses
 * @route   GET /api/courses/my-schedule
 * @access  Private
 */
const getMySchedule = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        if (!user || !user.enrolledCourses || user.enrolledCourses.length === 0) {
            return res.status(200).json({
                success: true,
                count: 0,
                data: [],
            });
        }

        // Get all classes from enrolled courses
        const classes = await Class.find({ courseId: { $in: user.enrolledCourses } })
            .populate('courseId', 'title subject educatorId')
            .populate('topicId', 'title description')
            .sort({ scheduledAt: 1 });

        // Populate educator details for each class
        const classesWithEducator = await Promise.all(
            classes.map(async (cls) => {
                const classObj = cls.toObject();
                if (classObj.courseId && classObj.courseId.educatorId) {
                    const educator = await User.findById(classObj.courseId.educatorId).select('name email');
                    classObj.educatorName = educator ? educator.name : 'Unknown';
                    classObj.courseName = classObj.courseId.title;
                    classObj.courseSubject = classObj.courseId.subject;
                    classObj.topicName = classObj.topicId ? classObj.topicId.title : 'Unknown';
                    classObj.topicDescription = classObj.topicId ? classObj.topicId.description : '';
                }
                return classObj;
            })
        );

        res.status(200).json({
            success: true,
            count: classesWithEducator.length,
            data: classesWithEducator,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching schedule',
            error: error.message,
        });
    }
};

/**
 * @desc    Mark class as completed for logged in user
 * @route   POST /api/courses/classes/:classId/complete
 * @access  Private
 */
const markClassCompleted = async (req, res) => {
    try {
        const classId = req.params.classId;
        const userId = req.user._id;

        // Check if class exists
        const cls = await Class.findById(classId);
        if (!cls) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        // Check if user is enrolled in the course
        const user = await User.findById(userId);
        if (!user.enrolledCourses.includes(cls.courseId)) {
            return res.status(403).json({
                success: false,
                message: 'You must be enrolled in the course to mark class as completed',
            });
        }

        // Check if already completed
        if (user.completedClasses.includes(classId)) {
            return res.status(200).json({
                success: true,
                message: 'Class already marked as completed',
            });
        }

        // Add class to completed classes
        user.completedClasses.push(classId);
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Class marked as completed',
            data: {
                classId: cls._id,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while marking class as completed',
            error: error.message,
        });
    }
};

/**
 * @desc    Bookmark a class
 * @route   POST /api/courses/classes/:classId/bookmark
 * @access  Private
 */
const bookmarkClass = async (req, res) => {
    try {
        const classId = req.params.classId;
        const userId = req.user._id;

        // Check if class exists
        const cls = await Class.findById(classId);
        if (!cls) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        // Check if class is recorded
        if (cls.type !== 'recorded') {
            return res.status(400).json({
                success: false,
                message: 'Only recorded classes can be bookmarked',
            });
        }

        // Check if user is enrolled in the course
        const user = await User.findById(userId);
        if (!user.enrolledCourses.includes(cls.courseId)) {
            return res.status(403).json({
                success: false,
                message: 'You must be enrolled in the course to bookmark a class',
            });
        }

        // Check if already bookmarked
        if (user.bookmarkedClasses.includes(classId)) {
            return res.status(200).json({
                success: true,
                message: 'Class already bookmarked',
            });
        }

        // Add class to bookmarked classes
        user.bookmarkedClasses.push(classId);
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Class bookmarked successfully',
            data: {
                classId: cls._id,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while bookmarking class',
            error: error.message,
        });
    }
};

/**
 * @desc    Remove bookmark from a class
 * @route   DELETE /api/courses/classes/:classId/bookmark
 * @access  Private
 */
const unbookmarkClass = async (req, res) => {
    try {
        const classId = req.params.classId;
        const userId = req.user._id;

        // Check if class exists
        const cls = await Class.findById(classId);
        if (!cls) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        const user = await User.findById(userId);

        // Check if class is bookmarked
        if (!user.bookmarkedClasses.includes(classId)) {
            return res.status(400).json({
                success: false,
                message: 'Class is not bookmarked',
            });
        }

        // Remove class from bookmarked classes
        user.bookmarkedClasses = user.bookmarkedClasses.filter(
            (id) => id.toString() !== classId
        );

        // Remove all notes for this class
        user.classNotes = user.classNotes.filter(
            (note) => note.classId.toString() !== classId
        );

        await user.save();

        res.status(200).json({
            success: true,
            message: 'Bookmark removed successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while removing bookmark',
            error: error.message,
        });
    }
};

/**
 * @desc    Get all bookmarked classes for logged in user
 * @route   GET /api/courses/bookmarks
 * @access  Private
 */
const getBookmarkedClasses = async (req, res) => {
    try {
        const userId = req.user._id;

        // Get user with populated bookmarked classes
        const user = await User.findById(userId).populate({
            path: 'bookmarkedClasses',
            populate: [
                {
                    path: 'topicId',
                    select: 'title position',
                },
                {
                    path: 'courseId',
                    select: 'title thumbnail educatorId',
                    populate: {
                        path: 'educatorId',
                        select: 'name',
                    },
                },
            ],
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        res.status(200).json({
            success: true,
            count: user.bookmarkedClasses.length,
            data: user.bookmarkedClasses,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching bookmarked classes',
            error: error.message,
        });
    }
};

/**
 * @desc    Get notes for a specific class
 * @route   GET /api/courses/classes/:classId/notes
 * @access  Private
 */
const getClassNotes = async (req, res) => {
    try {
        const classId = req.params.classId;
        const userId = req.user._id;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Filter notes for this specific class
        const notes = user.classNotes.filter(
            (note) => note.classId.toString() === classId
        );

        res.status(200).json({
            success: true,
            count: notes.length,
            data: notes,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching notes',
            error: error.message,
        });
    }
};

/**
 * @desc    Add a note to a class
 * @route   POST /api/courses/classes/:classId/notes
 * @access  Private
 */
const addClassNote = async (req, res) => {
    try {
        const classId = req.params.classId;
        const userId = req.user._id;
        const { content, isHighlighted } = req.body;

        if (!content || content.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Note content is required',
            });
        }

        // Check if class exists
        const cls = await Class.findById(classId);
        if (!cls) {
            return res.status(404).json({
                success: false,
                message: 'Class not found',
            });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Check if class is bookmarked
        if (!user.bookmarkedClasses.includes(classId)) {
            return res.status(400).json({
                success: false,
                message: 'You can only add notes to bookmarked classes',
            });
        }

        // Add note
        const newNote = {
            classId,
            content: content.trim(),
            isHighlighted: isHighlighted || false,
            createdAt: new Date(),
            updatedAt: new Date(),
        };

        user.classNotes.push(newNote);
        await user.save();

        // Get the added note (last one)
        const addedNote = user.classNotes[user.classNotes.length - 1];

        res.status(201).json({
            success: true,
            message: 'Note added successfully',
            data: addedNote,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while adding note',
            error: error.message,
        });
    }
};

/**
 * @desc    Update a note
 * @route   PUT /api/courses/classes/:classId/notes/:noteId
 * @access  Private
 */
const updateClassNote = async (req, res) => {
    try {
        const { classId, noteId } = req.params;
        const userId = req.user._id;
        const { content, isHighlighted } = req.body;

        if (!content || content.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Note content is required',
            });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Find the note
        const note = user.classNotes.id(noteId);
        if (!note) {
            return res.status(404).json({
                success: false,
                message: 'Note not found',
            });
        }

        // Verify note belongs to this class
        if (note.classId.toString() !== classId) {
            return res.status(400).json({
                success: false,
                message: 'Note does not belong to this class',
            });
        }

        // Update note
        note.content = content.trim();
        note.isHighlighted = isHighlighted !== undefined ? isHighlighted : note.isHighlighted;
        note.updatedAt = new Date();

        await user.save();

        res.status(200).json({
            success: true,
            message: 'Note updated successfully',
            data: note,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating note',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete a note
 * @route   DELETE /api/courses/classes/:classId/notes/:noteId
 * @access  Private
 */
const deleteClassNote = async (req, res) => {
    try {
        const { classId, noteId } = req.params;
        const userId = req.user._id;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Find the note
        const note = user.classNotes.id(noteId);
        if (!note) {
            return res.status(404).json({
                success: false,
                message: 'Note not found',
            });
        }

        // Verify note belongs to this class
        if (note.classId.toString() !== classId) {
            return res.status(400).json({
                success: false,
                message: 'Note does not belong to this class',
            });
        }

        // Remove note using pull method
        user.classNotes.pull(noteId);
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Note deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting note',
            error: error.message,
        });
    }
};

module.exports = {
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
};
