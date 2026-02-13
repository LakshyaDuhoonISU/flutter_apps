const express = require('express');
const Booking = require('../models/Booking');
const Event = require('../models/Event');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/bookings
 * Create a new booking (user only)
 * Body: { eventId, numberOfTickets }
 */
router.post('/', authenticate, authorize('user'), async (req, res) => {
    try {
        const { eventId, numberOfTickets } = req.body;

        // Validate required fields
        if (!eventId || !numberOfTickets) {
            return res.status(400).json({ 
                success: false, 
                message: 'Please provide eventId and numberOfTickets' 
            });
        }

        // Validate numberOfTickets
        if (numberOfTickets <= 0) {
            return res.status(400).json({ 
                success: false, 
                message: 'Number of tickets must be positive' 
            });
        }

        // Find the event
        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({ 
                success: false, 
                message: 'Event not found' 
            });
        }

        // Check ticket availability
        if (event.availableTickets < numberOfTickets) {
            return res.status(400).json({ 
                success: false, 
                message: `Insufficient tickets. Only ${event.availableTickets} tickets available` 
            });
        }

        // Reduce available tickets (atomic operation to prevent race conditions)
        const updatedEvent = await Event.findOneAndUpdate(
            { 
                _id: eventId, 
                availableTickets: { $gte: numberOfTickets } // Ensure tickets still available
            },
            { 
                $inc: { availableTickets: -numberOfTickets }, // Decrement available tickets
                $push: { attendees: req.user.id } // Add user to attendees
            },
            { new: true } // Return updated document
        );

        // If update failed, tickets were booked by someone else
        if (!updatedEvent) {
            return res.status(400).json({ 
                success: false, 
                message: 'Tickets no longer available. Please try again' 
            });
        }

        // Create booking record
        const booking = new Booking({
            user: req.user.id,
            event: eventId,
            numberOfTickets
        });

        await booking.save();

        // Populate booking details
        await booking.populate('event', 'title date location price');
        await booking.populate('user', 'name email');

        res.status(201).json({ 
            success: true, 
            message: 'Booking successful',
            booking 
        });

    } catch (error) {
        console.error('Create booking error:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Server error while creating booking',
            error: error.message 
        });
    }
});

/**
 * GET /api/bookings/my
 * Get all bookings for the authenticated user
 */
router.get('/my', authenticate, authorize('user'), async (req, res) => {
    try {
        // Find all bookings for the authenticated user
        const bookings = await Booking.find({ user: req.user.id })
            .populate('event', 'title date location price imageUrl')
            .sort({ bookingDate: -1 }); // Most recent first

        res.status(200).json({ 
            success: true, 
            count: bookings.length,
            bookings 
        });

    } catch (error) {
        console.error('Get user bookings error:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Server error while fetching bookings',
            error: error.message 
        });
    }
});

/**
 * GET /api/bookings/event/:id
 * Get all bookings for a specific event (organizer only - must be event creator)
 */
router.get('/event/:id', authenticate, authorize('organizer'), async (req, res) => {
    try {
        const eventId = req.params.id;

        // Find the event and verify ownership
        const event = await Event.findById(eventId);
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
                message: 'You can only view bookings for your own events' 
            });
        }

        // Find all bookings for this event
        const bookings = await Booking.find({ event: eventId })
            .populate('user', 'name email')
            .sort({ bookingDate: -1 }); // Most recent first

        // Calculate statistics
        const totalTicketsSold = bookings.reduce((sum, booking) => sum + booking.numberOfTickets, 0);
        const totalRevenue = totalTicketsSold * event.price;

        res.status(200).json({ 
            success: true, 
            count: bookings.length,
            totalTicketsSold,
            totalRevenue,
            bookings 
        });

    } catch (error) {
        console.error('Get event bookings error:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Server error while fetching event bookings',
            error: error.message 
        });
    }
});

module.exports = router;
