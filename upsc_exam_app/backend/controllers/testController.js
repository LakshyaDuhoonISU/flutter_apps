// Test Controller
// Handles test series and test submission

const Test = require('../models/Test');
const Question = require('../models/Question');
const TestResult = require('../models/TestResult');

/**
 * @desc    Get all tests for a course
 * @route   GET /api/tests/:courseId
 * @access  Private
 */
const getTestsByCourse = async (req, res) => {
    try {
        const { courseId } = req.params;

        // Get all tests for the course
        const tests = await Test.find({ courseId })
            .populate('createdBy', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: tests.length,
            data: tests,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching tests',
            error: error.message,
        });
    }
};

/**
 * @desc    Get single test with questions
 * @route   GET /api/test/:id
 * @access  Private
 */
const getTest = async (req, res) => {
    try {
        const { id } = req.params;

        // Get test details
        const test = await Test.findById(id)
            .populate('createdBy', 'name')
            .populate('courseId', 'title subject');

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Get all questions for this test
        // Include correct answers and explanations for educators/admins, hide for students
        const isEducator = req.user && (req.user.role === 'educator' || req.user.role === 'admin');
        const questionsQuery = Question.find({ testId: id })
            .populate('topicId', 'title');
        if (!isEducator) {
            questionsQuery.select('-correctAnswer -explanation'); // Don't send answers to students
        }
        const questions = await questionsQuery;

        res.status(200).json({
            success: true,
            data: {
                test,
                questions,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching test',
            error: error.message,
        });
    }
};

/**
 * @desc    Submit test and get results
 * @route   POST /api/test/submit
 * @access  Private
 */
const submitTest = async (req, res) => {
    try {
        const { testId, answers, totalTimeTaken } = req.body;
        const userId = req.user._id;

        // Validate input
        if (!testId || !answers || !Array.isArray(answers)) {
            return res.status(400).json({
                success: false,
                message: 'Please provide testId and answers array',
            });
        }

        // Get test details
        const test = await Test.findById(testId);
        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Get all questions with correct answers
        const questions = await Question.find({ testId });

        // Create a map for quick lookup
        const questionMap = {};
        questions.forEach(q => {
            questionMap[q._id.toString()] = q;
        });

        // Process answers and calculate results
        let correctCount = 0;
        let wrongCount = 0;
        let unattemptedCount = 0;
        let score = 0;

        const processedAnswers = answers.map(answer => {
            const question = questionMap[answer.questionId];

            if (!question) {
                return null;
            }

            // Check if question was attempted
            if (answer.selectedOption === -1 || answer.selectedOption === undefined) {
                unattemptedCount++;
                return {
                    questionId: answer.questionId,
                    selectedOption: -1,
                    isCorrect: false,
                    timeTaken: answer.timeTaken || 0,
                };
            }

            // Check if answer is correct
            const isCorrect = answer.selectedOption === question.correctAnswer;

            if (isCorrect) {
                correctCount++;
                score += question.marks;
            } else {
                wrongCount++;
            }

            return {
                questionId: answer.questionId,
                selectedOption: answer.selectedOption,
                isCorrect,
                timeTaken: answer.timeTaken || 0,
            };
        }).filter(a => a !== null);

        // Calculate accuracy
        const attemptedCount = correctCount + wrongCount;
        const accuracy = attemptedCount > 0
            ? ((correctCount / attemptedCount) * 100).toFixed(2)
            : 0;

        // Save test result
        const testResult = await TestResult.create({
            userId,
            testId,
            answers: processedAnswers,
            score,
            correctCount,
            wrongCount,
            unattemptedCount,
            accuracy,
            totalTimeTaken: totalTimeTaken || 0,
        });

        // Get detailed results with questions and explanations
        const detailedResults = await TestResult.findById(testResult._id)
            .populate({
                path: 'testId',
                select: 'title totalMarks totalQuestions',
            })
            .populate({
                path: 'answers.questionId',
                select: 'question options correctAnswer explanation difficulty',
            });

        res.status(201).json({
            success: true,
            message: 'Test submitted successfully',
            data: detailedResults,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while submitting test',
            error: error.message,
        });
    }
};

/**
 * @desc    Get test results for a user
 * @route   GET /api/test/results/:testId
 * @access  Private
 */
const getTestResults = async (req, res) => {
    try {
        const { testId } = req.params;
        const userId = req.user._id;

        // Get all results for this test by this user
        const results = await TestResult.find({ userId, testId })
            .populate('testId', 'title totalMarks totalQuestions')
            .sort({ attemptedAt: -1 });

        res.status(200).json({
            success: true,
            count: results.length,
            data: results,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching results',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new test (Educator only)
 * @route   POST /api/test/create
 * @access  Private/Educator
 */
const createTest = async (req, res) => {
    try {
        const { courseId, title, description, durationMinutes, totalMarks, questions } = req.body;

        // Validate input
        if (!title || !durationMinutes || !questions || !Array.isArray(questions)) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields',
            });
        }

        // Create test
        const test = await Test.create({
            courseId: courseId || null,
            title,
            description,
            durationMinutes,
            totalQuestions: questions.length,
            totalMarks: totalMarks || questions.length,
            createdBy: req.user._id,
        });

        // Create questions for this test
        const questionsWithTestId = questions.map(q => ({
            ...q,
            testId: test._id,
        }));

        await Question.insertMany(questionsWithTestId);

        res.status(201).json({
            success: true,
            message: 'Test created successfully',
            data: test,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating test',
            error: error.message,
        });
    }
};

/**
 * @desc    Get all standalone tests (not tied to course)
 * @route   GET /api/test/all
 * @access  Public
 */
const getAllTests = async (req, res) => {
    try {
        const tests = await Test.find({ courseId: null })
            .populate('createdBy', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: tests.length,
            data: tests,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching tests',
            error: error.message,
        });
    }
};

/**
 * @desc    Get educator's tests
 * @route   GET /api/test/my-tests
 * @access  Private/Educator
 */
const getMyTests = async (req, res) => {
    try {
        const tests = await Test.find({ createdBy: req.user._id, courseId: null })
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: tests.length,
            data: tests,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching tests',
            error: error.message,
        });
    }
};

/**
 * @desc    Update a test
 * @route   PUT /api/test/:id
 * @access  Private/Educator
 */
const updateTest = async (req, res) => {
    try {
        const test = await Test.findById(req.params.id);

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Check if user is the creator
        if (test.createdBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this test',
            });
        }

        const {
            title,
            description,
            durationMinutes,
            totalMarks,
            isFree,
        } = req.body;

        // Update fields
        if (title) test.title = title;
        if (description !== undefined) test.description = description;
        if (durationMinutes) test.durationMinutes = durationMinutes;
        if (totalMarks) test.totalMarks = totalMarks;
        if (isFree !== undefined) test.isFree = isFree;

        await test.save();

        res.status(200).json({
            success: true,
            message: 'Test updated successfully',
            data: test,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating test',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete a test
 * @route   DELETE /api/test/:id
 * @access  Private/Educator
 */
const deleteTest = async (req, res) => {
    try {
        const test = await Test.findById(req.params.id);

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Check if user is the creator
        if (test.createdBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this test',
            });
        }

        // Delete all questions for this test
        await Question.deleteMany({ testId: test._id });

        // Delete all test results
        await TestResult.deleteMany({ testId: test._id });

        // Delete the test
        await test.deleteOne();

        res.status(200).json({
            success: true,
            message: 'Test and all its questions deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting test',
            error: error.message,
        });
    }
};

/**
 * @desc    Add question to test
 * @route   POST /api/test/:id/question
 * @access  Private/Educator
 */
const addQuestion = async (req, res) => {
    try {
        const test = await Test.findById(req.params.id);

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Check if user is the creator
        if (test.createdBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to add questions to this test',
            });
        }

        const {
            question,
            options,
            correctAnswer,
            explanation,
            difficulty,
            marks,
        } = req.body;

        // Validation
        if (!question || !options || options.length !== 4 || correctAnswer === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Please provide question, 4 options, and correct answer',
            });
        }

        if (correctAnswer < 0 || correctAnswer > 3) {
            return res.status(400).json({
                success: false,
                message: 'Correct answer must be between 0 and 3',
            });
        }

        const newQuestion = await Question.create({
            testId: test._id,
            question,
            options,
            correctAnswer,
            explanation: explanation || '',
            difficulty: difficulty || 'Medium',
            marks: marks || 1,
            isPreviousYear: false,
        });

        // Update test's total questions count
        test.totalQuestions += 1;
        await test.save();

        res.status(201).json({
            success: true,
            message: 'Question added successfully',
            data: newQuestion,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while adding question',
            error: error.message,
        });
    }
};

/**
 * @desc    Update question in test
 * @route   PUT /api/test/:testId/question/:questionId
 * @access  Private/Educator
 */
const updateQuestion = async (req, res) => {
    try {
        const test = await Test.findById(req.params.testId);

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Check if user is the creator
        if (test.createdBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this question',
            });
        }

        const question = await Question.findById(req.params.questionId);

        if (!question || question.testId.toString() !== test._id.toString()) {
            return res.status(404).json({
                success: false,
                message: 'Question not found',
            });
        }

        const {
            question: questionText,
            options,
            correctAnswer,
            explanation,
            difficulty,
            marks,
        } = req.body;

        // Update fields
        if (questionText) question.question = questionText;
        if (options && options.length === 4) question.options = options;
        if (correctAnswer !== undefined) {
            if (correctAnswer < 0 || correctAnswer > 3) {
                return res.status(400).json({
                    success: false,
                    message: 'Correct answer must be between 0 and 3',
                });
            }
            question.correctAnswer = correctAnswer;
        }
        if (explanation !== undefined) question.explanation = explanation;
        if (difficulty) question.difficulty = difficulty;
        if (marks) question.marks = marks;

        await question.save();

        res.status(200).json({
            success: true,
            message: 'Question updated successfully',
            data: question,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating question',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete question from test
 * @route   DELETE /api/test/:testId/question/:questionId
 * @access  Private/Educator
 */
const deleteQuestion = async (req, res) => {
    try {
        const test = await Test.findById(req.params.testId);

        if (!test) {
            return res.status(404).json({
                success: false,
                message: 'Test not found',
            });
        }

        // Check if user is the creator
        if (test.createdBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this question',
            });
        }

        const question = await Question.findById(req.params.questionId);

        if (!question || question.testId.toString() !== test._id.toString()) {
            return res.status(404).json({
                success: false,
                message: 'Question not found',
            });
        }

        await question.deleteOne();

        // Update test's total questions count
        test.totalQuestions = Math.max(0, test.totalQuestions - 1);
        await test.save();

        res.status(200).json({
            success: true,
            message: 'Question deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting question',
            error: error.message,
        });
    }
};

/**
 * @desc    Get user's test history
 * @route   GET /api/test/history
 * @access  Private
 */
const getTestHistory = async (req, res) => {
    try {
        const results = await TestResult.find({ userId: req.user._id })
            .populate('testId', 'title durationMinutes totalMarks totalQuestions')
            .sort({ attemptedAt: -1 });

        res.status(200).json({
            success: true,
            count: results.length,
            data: results,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching test history',
            error: error.message,
        });
    }
};

/**
 * @desc    Get detailed test result
 * @route   GET /api/test/result/:resultId
 * @access  Private
 */
const getTestResult = async (req, res) => {
    try {
        const result = await TestResult.findById(req.params.resultId)
            .populate('testId', 'title totalMarks totalQuestions durationMinutes')
            .populate('userId', 'name email');

        if (!result) {
            return res.status(404).json({
                success: false,
                message: 'Test result not found',
            });
        }

        // Check if user owns this result
        if (result.userId._id.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to view this result',
            });
        }

        // Get questions with answers
        const questions = await Question.find({ testId: result.testId._id });

        // Map questions with user's answers
        const questionsWithAnswers = questions.map((question) => {
            const userAnswer = result.answers.find(
                (ans) => ans.questionId.toString() === question._id.toString()
            );

            return {
                ...question.toObject(),
                userAnswer: userAnswer ? userAnswer.selectedOption : -1,
                isCorrect: userAnswer ? userAnswer.isCorrect : false,
                timeTaken: userAnswer ? userAnswer.timeTaken : 0,
            };
        });

        res.status(200).json({
            success: true,
            data: {
                ...result.toObject(),
                questions: questionsWithAnswers,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching test result',
            error: error.message,
        });
    }
};

module.exports = {
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
};
