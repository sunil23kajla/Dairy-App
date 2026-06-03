require('dotenv').config();
const express = require('express');
const mongoose = require('./db');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI;
if (MONGO_URI) {
  mongoose.connect(MONGO_URI)
    .then(() => console.log('Connected to MongoDB Atlas (Production)'))
    .catch(err => console.error('MongoDB Atlas connection error:', err));
} else {
  mongoose.connect('mock')
    .then(() => console.log('Connected to Mock MongoDB (Local)'))
    .catch(err => console.error('Mock MongoDB connection error:', err));
}

// Routes
app.get('/', (req, res) => {
  res.status(200).send('Dairy API is running');
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/sync', require('./routes/sync'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
