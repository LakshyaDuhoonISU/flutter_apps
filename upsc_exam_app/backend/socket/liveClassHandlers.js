// Socket.IO Handlers for Live Class Interactions
// Handles real-time chat, polls, and doubts

const LiveChat = require('../models/LiveChat');
const LivePoll = require('../models/LivePoll');
const LiveDoubt = require('../models/LiveDoubt');
const Class = require('../models/Class');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Track scheduled cleanup timers { classId: timerId }
const cleanupTimers = {};

// Clean up all live data for a class and notify all connected clients
const cleanupClassData = async (io, classId) => {
    try {
        await LiveChat.deleteMany({ classId });
        await LivePoll.deleteMany({ classId });
        await LiveDoubt.deleteMany({ classId });

        console.log(`Cleaned up live data for class ${classId}`);

        // Notify anyone still in the room
        io.to(`class-${classId}`).emit('class-ended', {
            classId,
            message: 'This class has ended. Chat, polls, and doubts have been cleared.',
        });
    } catch (error) {
        console.error(`Error cleaning up class ${classId}:`, error);
    }

    // Remove the timer reference
    delete cleanupTimers[classId];
};

// Schedule cleanup for a class based on its end time
const scheduleCleanup = (io, classId, endsAt) => {
    // Cancel any existing timer for this class
    if (cleanupTimers[classId]) {
        clearTimeout(cleanupTimers[classId]);
    }

    const now = Date.now();
    const msUntilEnd = endsAt.getTime() - now;

    if (msUntilEnd <= 0) {
        // Already ended — clean up immediately
        cleanupClassData(io, classId);
    } else {
        console.log(`Scheduled cleanup for class ${classId} in ${Math.round(msUntilEnd / 1000)}s`);
        cleanupTimers[classId] = setTimeout(() => {
            cleanupClassData(io, classId);
        }, msUntilEnd);
    }
};

// Authenticate socket connection
const authenticateSocket = async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('Authentication error'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id).select('-password');

        if (!user) {
            return next(new Error('User not found'));
        }

        socket.user = user;
        next();
    } catch (error) {
        next(new Error('Authentication error'));
    }
};

// Initialize socket handlers
const initializeSocketHandlers = (io) => {
    // Authentication middleware
    io.use(authenticateSocket);

    io.on('connection', (socket) => {
        console.log(`User connected: ${socket.user.name} (${socket.user.role})`);

        // Join class room
        socket.on('join-class', async (classId) => {
            socket.join(`class-${classId}`);
            socket.classId = classId;
            console.log(`${socket.user.name} joined class ${classId}`);

            try {
                // Check if this class is still live
                const classData = await Class.findById(classId);
                if (classData && classData.scheduledAt) {
                    const scheduledAt = new Date(classData.scheduledAt);
                    const durationMs = (classData.durationMinutes || 60) * 60 * 1000;
                    const endsAt = new Date(scheduledAt.getTime() + durationMs);
                    const now = new Date();

                    if (now > endsAt) {
                        // Class is already recorded — clean up and notify
                        await cleanupClassData(io, classId);
                        return;
                    }

                    // Schedule cleanup when this class ends (if not already scheduled)
                    if (!cleanupTimers[classId]) {
                        scheduleCleanup(io, classId, endsAt);
                    }
                }

                // Send existing chats
                const chats = await LiveChat.find({
                    classId,
                    isDeleted: false
                })
                    .sort({ createdAt: 1 })
                    .limit(100);

                socket.emit('chat-history', chats);

                // Send all polls for this class (active + ended)
                const allPolls = await LivePoll.find({ classId }).sort({ createdAt: 1 });

                if (allPolls.length > 0) {
                    if (socket.user.role === 'student') {
                        // Strip vote counts from polls that are still active
                        const pollsForStudent = allPolls.map(poll => {
                            if (poll.isActive && new Date() < poll.endsAt) {
                                return {
                                    _id: poll._id,
                                    classId: poll.classId,
                                    question: poll.question,
                                    options: poll.options.map(opt => ({ text: opt.text })),
                                    endsAt: poll.endsAt,
                                    durationSeconds: poll.durationSeconds,
                                    isActive: true,
                                };
                            }
                            return poll; // ended poll: show full results
                        });
                        socket.emit('polls-history', pollsForStudent);
                    } else {
                        socket.emit('polls-history', allPolls);
                    }
                }

                // Send doubts (educators see all, students see only their own)
                const doubtQuery = {
                    classId,
                    isDeleted: false,
                };
                if (socket.user.role === 'student') {
                    doubtQuery.studentId = socket.user._id;
                }

                const doubts = await LiveDoubt.find(doubtQuery)
                    .sort({ createdAt: -1 })
                    .limit(50);

                socket.emit('doubts-list', doubts);
            } catch (error) {
                console.error('Error loading class data:', error);
            }
        });

        // Leave class room
        socket.on('leave-class', (classId) => {
            socket.leave(`class-${classId}`);
            console.log(`${socket.user.name} left class ${classId}`);
        });

        // ===== CHAT HANDLERS =====

        // Send chat message
        socket.on('send-chat', async (data) => {
            try {
                const { classId, message } = data;

                if (!message || message.trim().length === 0) {
                    return socket.emit('error', { message: 'Message cannot be empty' });
                }

                if (message.length > 500) {
                    return socket.emit('error', { message: 'Message too long' });
                }

                const chat = await LiveChat.create({
                    classId,
                    userId: socket.user._id,
                    userName: socket.user.name,
                    userRole: socket.user.role,
                    message: message.trim(),
                });

                // Broadcast to all in class
                io.to(`class-${classId}`).emit('new-chat', chat);
            } catch (error) {
                console.error('Error sending chat:', error);
                socket.emit('error', { message: 'Failed to send message' });
            }
        });

        // Delete chat (educators/admins only)
        socket.on('delete-chat', async (data) => {
            try {
                const { chatId, classId } = data;

                if (!['educator', 'admin'].includes(socket.user.role)) {
                    return socket.emit('error', { message: 'Unauthorized' });
                }

                const chat = await LiveChat.findByIdAndUpdate(
                    chatId,
                    {
                        isDeleted: true,
                        deletedBy: socket.user._id,
                    },
                    { new: true }
                );

                if (chat) {
                    io.to(`class-${classId}`).emit('chat-deleted', { chatId });
                }
            } catch (error) {
                console.error('Error deleting chat:', error);
                socket.emit('error', { message: 'Failed to delete message' });
            }
        });

        // ===== POLL HANDLERS =====

        // Create poll (educators/admins only)
        socket.on('create-poll', async (data) => {
            try {
                const { classId, question, options, durationSeconds } = data;

                if (!['educator', 'admin'].includes(socket.user.role)) {
                    return socket.emit('error', { message: 'Unauthorized' });
                }

                if (!question || options.length < 2 || options.length > 5) {
                    return socket.emit('error', {
                        message: 'Invalid poll data. Need 2-5 options.'
                    });
                }

                const now = new Date();
                const endsAt = new Date(now.getTime() + (durationSeconds || 60) * 1000);

                const poll = await LivePoll.create({
                    classId,
                    createdBy: socket.user._id,
                    question,
                    options: options.map(text => ({ text, votes: 0 })),
                    durationSeconds: durationSeconds || 60,
                    startsAt: now,
                    endsAt,
                });

                // Send poll to all students (without vote counts)
                const studentPollData = {
                    _id: poll._id,
                    question: poll.question,
                    options: poll.options.map(opt => ({ text: opt.text })),
                    endsAt: poll.endsAt,
                    durationSeconds: poll.durationSeconds,
                };

                io.to(`class-${classId}`).emit('new-poll', studentPollData);

                // Send full poll to educator
                socket.emit('poll-created', poll);

                // Auto-end poll after duration
                setTimeout(async () => {
                    try {
                        const endedPoll = await LivePoll.findByIdAndUpdate(
                            poll._id,
                            { isActive: false },
                            { new: true }
                        );

                        if (endedPoll) {
                            io.to(`class-${classId}`).emit('poll-ended', {
                                pollId: poll._id
                            });

                            // Send results to all educators/admins
                            const educatorSockets = await io.in(`class-${classId}`).fetchSockets();
                            for (const sock of educatorSockets) {
                                if (sock.user && ['educator', 'admin'].includes(sock.user.role)) {
                                    sock.emit('poll-results', endedPoll);
                                }
                            }
                        }
                    } catch (error) {
                        console.error('Error ending poll:', error);
                    }
                }, durationSeconds * 1000);
            } catch (error) {
                console.error('Error creating poll:', error);
                socket.emit('error', { message: 'Failed to create poll' });
            }
        });

        // Vote on poll
        socket.on('vote-poll', async (data) => {
            try {
                const { pollId, optionIndex, classId } = data;

                if (socket.user.role !== 'student') {
                    return socket.emit('error', { message: 'Only students can vote' });
                }

                const poll = await LivePoll.findById(pollId);

                if (!poll || !poll.isActive || new Date() > poll.endsAt) {
                    return socket.emit('error', { message: 'Poll is not active' });
                }

                // Check if already voted
                const alreadyVoted = poll.voters.find(
                    v => v.userId.toString() === socket.user._id.toString()
                );

                if (alreadyVoted) {
                    return socket.emit('error', { message: 'Already voted' });
                }

                // Add vote
                poll.options[optionIndex].votes += 1;
                poll.voters.push({
                    userId: socket.user._id,
                    selectedOption: optionIndex,
                });

                await poll.save();

                socket.emit('vote-recorded', { pollId });

                // Update educator with live results
                const educatorSockets = await io.in(`class-${classId}`).fetchSockets();
                for (const sock of educatorSockets) {
                    if (sock.user && sock.user.role === 'educator') {
                        sock.emit('poll-update', poll);
                    }
                }
            } catch (error) {
                console.error('Error voting on poll:', error);
                socket.emit('error', { message: 'Failed to record vote' });
            }
        });

        // ===== DOUBT HANDLERS =====

        // Raise doubt (students only)
        socket.on('raise-doubt', async (data) => {
            try {
                const { classId, question } = data;

                if (socket.user.role !== 'student') {
                    return socket.emit('error', { message: 'Only students can raise doubts' });
                }

                if (!question || question.trim().length === 0) {
                    return socket.emit('error', { message: 'Question cannot be empty' });
                }

                const doubt = await LiveDoubt.create({
                    classId,
                    studentId: socket.user._id,
                    studentName: socket.user.name,
                    question: question.trim(),
                });

                // Notify educator
                const educatorSockets = await io.in(`class-${classId}`).fetchSockets();
                for (const sock of educatorSockets) {
                    if (sock.user && sock.user.role === 'educator') {
                        sock.emit('new-doubt', doubt);
                    }
                }

                // Confirm to student
                socket.emit('doubt-raised', doubt);
            } catch (error) {
                console.error('Error raising doubt:', error);
                socket.emit('error', { message: 'Failed to raise doubt' });
            }
        });

        // Answer doubt (educators/admins only)
        socket.on('answer-doubt', async (data) => {
            try {
                const { doubtId, answer, classId } = data;

                if (!['educator', 'admin'].includes(socket.user.role)) {
                    return socket.emit('error', { message: 'Unauthorized' });
                }

                const doubt = await LiveDoubt.findByIdAndUpdate(
                    doubtId,
                    {
                        answer,
                        answeredBy: socket.user._id,
                        answeredAt: new Date(),
                        status: 'answered',
                    },
                    { new: true }
                );

                if (doubt) {
                    // Notify the student who raised the doubt
                    const allSockets = await io.in(`class-${classId}`).fetchSockets();
                    for (const sock of allSockets) {
                        if (sock.user && sock.user._id.toString() === doubt.studentId.toString()) {
                            sock.emit('doubt-answered', doubt);
                        }
                        // Also update all educators/admins so their view refreshes live
                        if (sock.user && ['educator', 'admin'].includes(sock.user.role)) {
                            sock.emit('doubt-answer-recorded', doubt);
                        }
                    }
                }
            } catch (error) {
                console.error('Error answering doubt:', error);
                socket.emit('error', { message: 'Failed to answer doubt' });
            }
        });

        // Delete doubt (educators/admins only)
        socket.on('delete-doubt', async (data) => {
            try {
                const { doubtId, classId } = data;

                if (!['educator', 'admin'].includes(socket.user.role)) {
                    return socket.emit('error', { message: 'Unauthorized' });
                }

                const doubt = await LiveDoubt.findByIdAndUpdate(
                    doubtId,
                    {
                        isDeleted: true,
                        deletedBy: socket.user._id,
                        status: 'deleted',
                    },
                    { new: true }
                );

                if (doubt) {
                    // Notify all
                    io.to(`class-${classId}`).emit('doubt-deleted', { doubtId });
                }
            } catch (error) {
                console.error('Error deleting doubt:', error);
                socket.emit('error', { message: 'Failed to delete doubt' });
            }
        });

        // Disconnect
        socket.on('disconnect', () => {
            console.log(`User disconnected: ${socket.user.name}`);
        });
    });
};

module.exports = { initializeSocketHandlers };
