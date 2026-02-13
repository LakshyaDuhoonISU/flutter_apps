const express = require('express');
const authRouter = require('./routes/authRouter');
const bookRouter = require('./routes/bookRouter');
const issueBookRouter = require('./routes/issueBookRouter');
const db = require('./db');
const cors = require('cors');

const app = express();
app.use(cors("*"));
app.use(express.json());

app.use('/api/auth', authRouter);
app.use('/api/books', bookRouter);
app.use('/api/issue', issueBookRouter);

app.listen(4000, () => {
    console.log('Server is running on port 4000');
});