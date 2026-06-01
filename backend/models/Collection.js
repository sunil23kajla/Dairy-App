const mongoose = require('../db');

const collectionSchema = new mongoose.Schema({
  localId: { type: String, required: true }, // UUID from local DB
  dairyCode: { type: String, required: true },
  farmerId: { type: String, required: true },
  farmerName: { type: String },
  date: { type: Date, required: true },
  session: { type: String, enum: ['morning', 'evening'], required: true },
  liters: { type: Number, required: true },
  fat: { type: Number },
  snf: { type: Number },
  rate: { type: Number, required: true },
  totalAmount: { type: Number, required: true },
  isPendingFat: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

collectionSchema.index({ localId: 1 }, { unique: true });

module.exports = mongoose.model('Collection', collectionSchema);
