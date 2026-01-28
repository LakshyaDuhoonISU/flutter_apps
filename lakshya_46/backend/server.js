const express = require('express');
const db = require('./db');
const bookRouter = require('./routes/bookRouter');
const cors = require('cors');

const app = express();
app.use(cors("*"));
app.use(express.json());
app.use('/books', bookRouter);

app.listen(4000, () => {
    console.log(`Server is running on port 4000`);
});