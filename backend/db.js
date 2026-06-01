const mongoose = require('mongoose');
const mockMongoose = require('./mockMongoose');

if (process.env.MONGO_URI) {
  // Use real MongoDB if URI is provided in .env
  module.exports = mongoose;
} else {
  // Fallback to local mock mongoose
  module.exports = mockMongoose;
}
