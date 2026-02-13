const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    description: {
        type: String,
        required: true,
    },
    date: {
        type: Date,
        required: true,
    },
    imageUrl: {
        type: String,
        required: true,
    },
    location: {
        type: String,
        required: true,
    },
    totalTickets: {
        type: Number,
        required: true,
    },
    availableTickets: {
        type: Number,
        required: true,
    },
    price: {
        type: Number,
        required: true,
    },
    organizer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    attendees: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    }],
});

const Event = mongoose.model('Event', eventSchema);

module.exports = Event;