const mongoose = require('../db');

const dairySchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  mobile: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  workers: {
    type: Map,
    of: String // MPIN: Worker Name
  },
  fatFactor: { type: Number, default: 9.0 },
  snfFactor: { type: Number, default: 9.0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Dairy', dairySchema);
