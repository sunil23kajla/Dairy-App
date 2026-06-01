const mongoose = require('../mockMongoose');

const farmerSchema = new mongoose.Schema({
  id: { type: String, required: true }, // Local ID like F001
  dairyCode: { type: String, required: true },
  name: { type: String, required: true },
  mobile: { type: String },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Composite unique index
farmerSchema.index({ dairyCode: 1, id: 1 }, { unique: true });

module.exports = mongoose.model('Farmer', farmerSchema);
