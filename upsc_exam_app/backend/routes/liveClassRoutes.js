// Live Class Routes
// Routes for managing live class data cleanup

const express = require('express');
const router = express.Router();
const LiveChat = require('../models/LiveChat');
const LivePoll = require('../models/LivePoll');
const LiveDoubt = require('../models/LiveDoubt');
const { protect } = require('../middleware/authMiddleware');
const { restrictTo } = require('../middleware/roleMiddleware');

// @route   DELETE /api/live-class/:classId/cleanup
// @desc    Clean up all live class data (chats, polls, doubts) for a class
// @access  Private (Educator/Admin)
router.delete(
    '/:classId/cleanup',
    protect,
    restrictTo('educator', 'admin'),
    async (req, res) => {
        try {
            const { classId } = req.params;

            // Delete all chats for this class
            const chatsDeleted = await LiveChat.deleteMany({ classId });

            // Delete all polls for this class
            const pollsDeleted = await LivePoll.deleteMany({ classId });

            // Delete all doubts for this class
            const doubtsDeleted = await LiveDoubt.deleteMany({ classId });

            res.status(200).json({
                success: true,
                message: 'Live class data cleaned up successfully',
                data: {
                    chatsDeleted: chatsDeleted.deletedCount,
                    pollsDeleted: pollsDeleted.deletedCount,
                    doubtsDeleted: doubtsDeleted.deletedCount,
                },
            });
        } catch (error) {
            console.error('Error cleaning up live class data:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to clean up live class data',
                error: error.message,
            });
        }
    }
);

// @route   POST /api/live-class/cleanup-recorded
// @desc    Clean up data for all classes that have transitioned to recorded
// @access  Private (Admin only)
router.post(
    '/cleanup-recorded',
    protect,
    restrictTo('admin'),
    async (req, res) => {
        try {
            // Get all unique classIds from live data
            const chatClassIds = await LiveChat.distinct('classId');
            const pollClassIds = await LivePoll.distinct('classId');
            const doubtClassIds = await LiveDoubt.distinct('classId');

            const allClassIds = [
                ...new Set([...chatClassIds, ...pollClassIds, ...doubtClassIds]),
            ];

            // For each classId, check if the class is still live
            // This requires checking against the Class model
            const Class = require('../models/Class');

            let totalCleaned = 0;
            const cleanupResults = [];

            for (const classId of allClassIds) {
                try {
                    const classData = await Class.findById(classId);

                    if (!classData) {
                        // Class doesn't exist, clean up data
                        await LiveChat.deleteMany({ classId });
                        await LivePoll.deleteMany({ classId });
                        await LiveDoubt.deleteMany({ classId });
                        totalCleaned++;
                        cleanupResults.push({
                            classId,
                            reason: 'Class not found',
                        });
                        continue;
                    }

                    // Check if class is now recorded (scheduledAt + duration has passed)
                    const scheduledAt = new Date(classData.scheduledAt);
                    const durationMs = (classData.durationMinutes || 60) * 60 * 1000;
                    const endTime = new Date(scheduledAt.getTime() + durationMs);
                    const now = new Date();

                    if (now > endTime) {
                        // Class is recorded, clean up live data
                        await LiveChat.deleteMany({ classId });
                        await LivePoll.deleteMany({ classId });
                        await LiveDoubt.deleteMany({ classId });
                        totalCleaned++;
                        cleanupResults.push({
                            classId,
                            reason: 'Class is now recorded',
                            endTime,
                        });
                    }
                } catch (err) {
                    console.error(`Error processing class ${classId}:`, err);
                }
            }

            res.status(200).json({
                success: true,
                message: `Cleaned up data for ${totalCleaned} recorded classes`,
                data: {
                    totalClassesProcessed: allClassIds.length,
                    totalCleaned,
                    cleanupResults,
                },
            });
        } catch (error) {
            console.error('Error in bulk cleanup:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to clean up recorded classes',
                error: error.message,
            });
        }
    }
);

module.exports = router;
