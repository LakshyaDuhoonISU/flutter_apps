const express = require('express');
const Event = require('../models/Event');
const Booking = require('../models/Booking');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/admin/events
 * Get all events (admin only)
 */
router.get('/events', authenticate, authorize('admin'), async (req, res) => {
    try {
        // Get all events with organizer information
        const events = await Event.find()
            .populate('organizer', 'name email')
            .sort({ date: 1 });

        res.status(200).json({
            success: true,
            count: events.length,
            events
        });

    } catch (error) {
        console.error('Admin get events error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching events',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/bookings
 * Get all bookings (admin only)
 */
router.get('/bookings', authenticate, authorize('admin'), async (req, res) => {
    try {
        // Get all bookings with user and event information
        const bookings = await Booking.find()
            .populate('user', 'name email')
            .populate('event', 'title date location price')
            .sort({ bookingDate: -1 });

        res.status(200).json({
            success: true,
            count: bookings.length,
            bookings
        });

    } catch (error) {
        console.error('Admin get bookings error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching bookings',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/stats
 * Get analytics and statistics (admin only)
 * Uses MongoDB aggregation pipelines for efficient data processing
 */
router.get('/stats', authenticate, authorize('admin'), async (req, res) => {
    try {
        // Aggregation 1: Total tickets sold per event
        const ticketsSoldPerEvent = await Booking.aggregate([
            {
                // Group by event and sum numberOfTickets
                $group: {
                    _id: '$event',
                    totalTicketsSold: { $sum: '$numberOfTickets' },
                    totalBookings: { $sum: 1 }
                }
            },
            {
                // Lookup event details
                $lookup: {
                    from: 'events',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'eventDetails'
                }
            },
            {
                // Unwind the eventDetails array (creates a document for each event array element)
                $unwind: '$eventDetails'
            },
            {
                // Calculate revenue for each event (project is used to select which fields to show and can be used to create new fields)
                $project: {
                    eventId: '$_id',
                    eventTitle: '$eventDetails.title',
                    totalTicketsSold: 1,
                    totalBookings: 1,
                    price: '$eventDetails.price',
                    revenue: {
                        $multiply: ['$totalTicketsSold', '$eventDetails.price']
                    }
                }
            },
            {
                // Sort by revenue descending
                $sort: { revenue: -1 }
            }
        ]);

        // Aggregation 2: Overall statistics
        const overallStats = await Booking.aggregate([
            {
                // Calculate total bookings and tickets
                $group: {
                    _id: null, // id null because we want overall totals, not grouped by any field
                    totalBookings: { $sum: 1 },
                    totalTicketsSold: { $sum: '$numberOfTickets' }
                }
            }
        ]);

        // Aggregation 3: Top users by bookings
        const topUsers = await Booking.aggregate([
            {
                // Group by user
                $group: {
                    _id: '$user',
                    totalBookings: { $sum: 1 },
                    totalTickets: { $sum: '$numberOfTickets' }
                }
            },
            {
                // Lookup user details
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'userInfo'
                }
            },
            {
                // Unwind user info
                $unwind: '$userInfo'
            },
            {
                // Project required fields
                $project: {
                    userId: '$_id',
                    userName: '$userInfo.name',
                    userEmail: '$userInfo.email',
                    totalBookings: 1,
                    totalTickets: 1
                }
            },
            {
                // Sort by total bookings
                $sort: { totalBookings: -1 }
            },
            {
                // Limit to top 10
                $limit: 10
            }
        ]);

        // Count total events
        const totalEvents = await Event.countDocuments();

        // Calculate total revenue from aggregation 1
        const totalRevenue = ticketsSoldPerEvent.reduce((sum, event) => sum + event.revenue, 0);

        res.status(200).json({
            success: true,
            analytics: {
                overview: {
                    totalEvents,
                    totalBookings: overallStats[0]?.totalBookings || 0,
                    totalTicketsSold: overallStats[0]?.totalTicketsSold || 0,
                    totalRevenue
                },
                eventStats: ticketsSoldPerEvent, // Contains both tickets sold AND revenue per event
                topUsers
            }
        });

    } catch (error) {
        console.error('Admin stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while generating statistics',
            error: error.message
        });
    }
});

/**
 * PUT /api/admin/events/:id
 * Update any event (admin only)
 */
router.put('/events/:id', authenticate, authorize('admin'), async (req, res) => {
    try {
        const { title, description, date, imageUrl, location, price, totalTickets } = req.body;

        const event = await Event.findById(req.params.id);

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Update event fields if provided
        if (title) event.title = title;
        if (description) event.description = description;
        if (date) event.date = date;
        if (imageUrl) event.imageUrl = imageUrl;
        if (location) event.location = location;
        if (price !== undefined) event.price = price;

        // Handle totalTickets update
        if (totalTickets !== undefined) {
            const ticketsSold = event.totalTickets - event.availableTickets;

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
            message: 'Event updated successfully by admin',
            event
        });

    } catch (error) {
        console.error('Admin update event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while updating event',
            error: error.message
        });
    }
});

/**
 * DELETE /api/admin/events/:id
 * Delete any event (admin only)
 */
router.delete('/events/:id', authenticate, authorize('admin'), async (req, res) => {
    try {
        const event = await Event.findById(req.params.id);

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        await Event.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Event deleted successfully by admin'
        });

    } catch (error) {
        console.error('Admin delete event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while deleting event',
            error: error.message
        });
    }
});

module.exports = router;
