const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/itm_flutter_lms');

const db = mongoose.connection;

db.on('connected', () => {
    console.log('Connected to MongoDB Successfully...');
})

db.on('error', (error) => {
    console.log('Error connecting to MongoDB: ', error);
})

module.exports = db;