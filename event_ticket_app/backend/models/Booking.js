const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    event: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Event',
        required: true,
    },
    numberOfTickets: {
        type: Number,
        required: true,
    },
    bookingDate: {
        type: Date,
        default: Date.now,
    },
});

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;