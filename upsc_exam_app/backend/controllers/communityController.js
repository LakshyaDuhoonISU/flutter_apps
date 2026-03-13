// Community Controller
// Handles community forum posts and discussions

const CommunityPost = require('../models/CommunityPost');

/**
 * @desc    Get all community posts
 * @route   GET /api/community
 * @access  Public
 */
const getPosts = async (req, res) => {
    try {
        const { category, page = 1, limit = 20 } = req.query;

        let query = {};

        // Filter by category if provided
        if (category) {
            query.category = category;
        }

        // Calculate pagination
        const skip = (page - 1) * limit;

        // Get posts with pagination, pinned posts first
        const posts = await CommunityPost.find(query)
            .populate('createdBy', 'name role')
            .populate('replies.userId', 'name role')
            .sort({ isPinned: -1, createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        // Get total count for pagination
        const total = await CommunityPost.countDocuments(query);

        res.status(200).json({
            success: true,
            count: posts.length,
            total,
            page: parseInt(page),
            pages: Math.ceil(total / limit),
            data: posts,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching posts',
            error: error.message,
        });
    }
};

/**
 * @desc    Get single post by ID
 * @route   GET /api/community/:id
 * @access  Public
 */
const getPost = async (req, res) => {
    try {
        const { id } = req.params;

        const post = await CommunityPost.findById(id)
            .populate('createdBy', 'name role')
            .populate('replies.userId', 'name role');

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        res.status(200).json({
            success: true,
            data: post,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching post',
            error: error.message,
        });
    }
};

/**
 * @desc    Create new community post
 * @route   POST /api/community
 * @access  Private
 */
const createPost = async (req, res) => {
    try {
        const { title, content, category } = req.body;

        // Validate input
        if (!title || !content) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title and content',
            });
        }

        // Create post
        const post = await CommunityPost.create({
            title,
            content,
            category: category || 'General Discussion',
            createdBy: req.user._id,
        });

        // Populate creator details
        await post.populate('createdBy', 'name role');

        res.status(201).json({
            success: true,
            message: 'Post created successfully',
            data: post,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating post',
            error: error.message,
        });
    }
};

/**
 * @desc    Add reply to a post
 * @route   POST /api/community/reply/:postId
 * @access  Private
 */
const addReply = async (req, res) => {
    try {
        const { postId } = req.params;
        const { message } = req.body;

        // Validate input
        if (!message) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a message',
            });
        }

        // Find post
        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Check if post is locked
        if (post.isLocked) {
            return res.status(403).json({
                success: false,
                message: 'This post is locked and cannot receive replies',
            });
        }

        // Add reply
        post.replies.push({
            userId: req.user._id,
            message,
            createdAt: Date.now(),
        });

        await post.save();

        // Populate the new reply's user details
        await post.populate('replies.userId', 'name role');

        res.status(201).json({
            success: true,
            message: 'Reply added successfully',
            data: post,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while adding reply',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete a reply from a post
 * @route   DELETE /api/community/reply/:postId/:replyId
 * @access  Private
 */
const deleteReply = async (req, res) => {
    try {
        const { postId, replyId } = req.params;
        const userId = req.user._id;
        const userRole = req.user.role;

        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Find the reply
        const reply = post.replies.id(replyId);

        if (!reply) {
            return res.status(404).json({
                success: false,
                message: 'Reply not found',
            });
        }

        // Check if user is educator or reply owner
        const isOwner = reply.userId.toString() === userId.toString();
        const isEducator = userRole === 'educator';

        if (!isOwner && !isEducator) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete this reply',
            });
        }

        // Remove the reply
        reply.deleteOne();
        await post.save();

        res.status(200).json({
            success: true,
            message: 'Reply deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting reply',
            error: error.message,
        });
    }
};

/**
 * @desc    Upvote a post
 * @route   POST /api/community/upvote/:postId
 * @access  Private
 */
const upvotePost = async (req, res) => {
    try {
        const { postId } = req.params;
        const userId = req.user._id;

        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Check if user already upvoted
        const alreadyUpvoted = post.upvotedBy.includes(userId);

        if (alreadyUpvoted) {
            // Remove upvote
            post.upvotedBy = post.upvotedBy.filter(
                id => id.toString() !== userId.toString()
            );
            post.upvotes -= 1;
        } else {
            // Add upvote
            post.upvotedBy.push(userId);
            post.upvotes += 1;
        }

        await post.save();

        res.status(200).json({
            success: true,
            message: alreadyUpvoted ? 'Upvote removed' : 'Post upvoted',
            data: {
                upvotes: post.upvotes,
                upvoted: !alreadyUpvoted,
            },
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while upvoting post',
            error: error.message,
        });
    }
};

/**
 * @desc    Pin/Unpin a post (Educator only)
 * @route   PUT /api/community/pin/:postId
 * @access  Private/Educator
 */
const togglePinPost = async (req, res) => {
    try {
        const { postId } = req.params;

        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Toggle pin status
        post.isPinned = !post.isPinned;
        await post.save();

        res.status(200).json({
            success: true,
            message: post.isPinned ? 'Post pinned' : 'Post unpinned',
            data: post,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while pinning post',
            error: error.message,
        });
    }
};

/**
 * @desc    Lock/Unlock a post (Educator only)
 * @route   PUT /api/community/lock/:postId
 * @access  Private/Educator
 */
const toggleLockPost = async (req, res) => {
    try {
        const { postId } = req.params;

        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Toggle lock status
        post.isLocked = !post.isLocked;
        await post.save();

        res.status(200).json({
            success: true,
            message: post.isLocked ? 'Post locked' : 'Post unlocked',
            data: post,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while locking post',
            error: error.message,
        });
    }
};

/**
 * @desc    Delete a post (Educator only or post owner)
 * @route   DELETE /api/community/:postId
 * @access  Private
 */
const deletePost = async (req, res) => {
    try {
        const { postId } = req.params;
        const userId = req.user._id;
        const userRole = req.user.role;

        const post = await CommunityPost.findById(postId);

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found',
            });
        }

        // Check if user is educator or post owner
        const isOwner = post.createdBy.toString() === userId.toString();
        const isEducator = userRole === 'educator';

        if (!isOwner && !isEducator) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete this post',
            });
        }

        await CommunityPost.findByIdAndDelete(postId);

        res.status(200).json({
            success: true,
            message: 'Post deleted successfully',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting post',
            error: error.message,
        });
    }
};

module.exports = {
    getPosts,
    getPost,
    createPost,
    addReply,
    deleteReply,
    upvotePost,
    togglePinPost,
    toggleLockPost,
    deletePost,
};
