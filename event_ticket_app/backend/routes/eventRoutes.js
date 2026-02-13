const express = require('express');
const Event = require('../models/Event');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/events
 * Create a new event (organizer only)
 * Body: { title, description, date, imageUrl, location, totalTickets, price }
 */
router.post('/', authenticate, authorize('organizer'), async (req, res) => {
    try {
        const { title, description, date, imageUrl, location, totalTickets, price } = req.body;

        // Validate required fields
        if (!title || !description || !date || !imageUrl || !location || !totalTickets || price === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields'
            });
        }

        // Validate totalTickets and price
        if (totalTickets <= 0 || price < 0) {
            return res.status(400).json({
                success: false,
                message: 'Total tickets must be positive and price must be non-negative'
            });
        }

        // Create new event with organizer from authenticated user
        const event = new Event({
            title,
            description,
            date,
            imageUrl,
            location,
            totalTickets,
            availableTickets: totalTickets, // Initially all tickets are available
            price,
            organizer: req.user.id
        });

        await event.save();

        res.status(201).json({
            success: true,
            message: 'Event created successfully',
            event
        });

    } catch (error) {
        console.error('Create event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while creating event',
            error: error.message
        });
    }
});

/**
 * GET /api/events/my-events
 * Get only the authenticated organizer's events
 */
router.get('/my-events', authenticate, authorize('organizer'), async (req, res) => {
    try {
        // Get only events created by this organizer
        const events = await Event.find({ organizer: req.user.id })
            .populate('organizer', 'name email')
            .sort({ date: 1 });

        res.status(200).json({
            success: true,
            count: events.length,
            events
        });

    } catch (error) {
        console.error('Get organizer events error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching events',
            error: error.message
        });
    }
});

/**
 * GET /api/events
 * Get all events (public access)
 */
router.get('/', async (req, res) => {
    try {
        // Get all events, sorted by date
        const events = await Event.find()
            .populate('organizer', 'name email')
            .sort({ date: 1 }); // Sort by date ascending

        res.status(200).json({
            success: true,
            count: events.length,
            events
        });

    } catch (error) {
        console.error('Get events error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching events',
            error: error.message
        });
    }
});

/**
 * GET /api/events/:id
 * Get a single event by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const event = await Event.findById(req.params.id)
            .populate('organizer', 'name email');

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        res.status(200).json({
            success: true,
            event
        });

    } catch (error) {
        console.error('Get event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching event',
            error: error.message
        });
    }
});

/**
 * PUT /api/events/:id
 * Update an event (organizer only - must be the event creator)
 * Body: { title, description, date, imageUrl, location, totalTickets, price }
 */
router.put('/:id', authenticate, authorize('organizer'), async (req, res) => {
    try {
        const event = await Event.findById(req.params.id);

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Check if the authenticated user is the organizer of this event
        if (event.organizer.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update your own events'
            });
        }

        // Update allowed fields
        const { title, description, date, imageUrl, location, totalTickets, price } = req.body;

        if (title) event.title = title;
        if (description) event.description = description;
        if (date) event.date = date;
        if (imageUrl) event.imageUrl = imageUrl;
        if (location) event.location = location;
        if (price !== undefined) event.price = price;

        // Handle totalTickets update carefully
        if (totalTickets !== undefined) {
            const ticketsSold = event.totalTickets - event.availableTickets;

            // Ensure new total is not less than tickets already sold
            if (totalTickets < ticketsSold) {
                return res.status(400).json({
                    success: false,
                    message: `Cannot reduce total tickets below ${ticketsSold} (already sold)`
                });
            }

            event.totalTickets = totalTickets;
            event.availableTickets = totalTickets - ticketsSold;
        }

        await event.save();

        res.status(200).json({
            success: true,
            message: 'Event updated successfully',
            event
        });

    } catch (error) {
        console.error('Update event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating event',
            error: error.message
        });
    }
});

/**
 * DELETE /api/events/:id
 * Delete an event (organizer only - must be the event creator)
 */
router.delete('/:id', authenticate, authorize('organizer'), async (req, res) => {
    try {
        const event = await Event.findById(req.params.id);

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Check if the authenticated user is the organizer of this event
        if (event.organizer.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only delete your own events'
            });
        }

        await Event.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Event deleted successfully'
        });

    } catch (error) {
        console.error('Delete event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting event',
            error: error.message
        });
    }
});

module.exports = router;
