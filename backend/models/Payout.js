const mongoose = require('../mockMongoose');

const payoutSchema = new mongoose.Schema({
  localId: { type: String, required: true }, // UUID from local DB
  dairyCode: { type: String, required: true },
  farmerId: { type: String, required: true },
  farmerName: { type: String },
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  paymentType: { type: String, required: true }, // Cash, UPI, Bank Transfer
  notes: { type: String },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

payoutSchema.index({ localId: 1 }, { unique: true });

module.exports = mongoose.model('Payout', payoutSchema);
