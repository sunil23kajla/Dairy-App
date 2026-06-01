const express = require('express');
const router = express.Router();
const Farmer = require('../models/Farmer');
const Collection = require('../models/Collection');
const Payout = require('../models/Payout');

// PUSH endpoint: Receive unsynced data from local SQLite
router.post('/push', async (req, res) => {
  try {
    const { dairyCode, farmers, collections, payouts } = req.body;
    
    if (!dairyCode) {
      return res.status(400).json({ success: false, message: 'dairyCode required' });
    }

    // 1. Upsert Farmers
    if (farmers && farmers.length > 0) {
      for (const f of farmers) {
        await Farmer.findOneAndUpdate(
          { dairyCode, id: f.id },
          { name: f.name, mobile: f.mobile, updatedAt: new Date() },
          { upsert: true, new: true }
        );
      }
    }

    // 2. Upsert Collections
    if (collections && collections.length > 0) {
      for (const c of collections) {
        await Collection.findOneAndUpdate(
          { localId: c.localId },
          { ...c, dairyCode, updatedAt: new Date() },
          { upsert: true, new: true }
        );
      }
    }

    // 3. Upsert Payouts
    if (payouts && payouts.length > 0) {
      for (const p of payouts) {
        await Payout.findOneAndUpdate(
          { localId: p.localId },
          { ...p, dairyCode, updatedAt: new Date() },
          { upsert: true, new: true }
        );
      }
    }

    res.json({ success: true, message: 'Sync push successful' });
  } catch (err) {
    console.error('Push error:', err);
    res.status(500).json({ success: false, message: 'Server error during push' });
  }
});

// PULL endpoint: Send all data for a specific dairy
router.get('/pull', async (req, res) => {
  try {
    const { dairyCode } = req.query;
    if (!dairyCode) {
      return res.status(400).json({ success: false, message: 'dairyCode required' });
    }

    const farmers = await Farmer.find({ dairyCode });
    const collections = await Collection.find({ dairyCode });
    const payouts = await Payout.find({ dairyCode });

    res.json({
      success: true,
      data: { farmers, collections, payouts }
    });
  } catch (err) {
    console.error('Pull error:', err);
    res.status(500).json({ success: false, message: 'Server error during pull' });
  }
});

// DELETE endpoint: Delete a collection
router.delete('/collection/:localId', async (req, res) => {
  try {
    const { localId } = req.params;
    await Collection.findOneAndDelete({ localId });
    res.json({ success: true, message: 'Collection deleted successfully' });
  } catch (err) {
    console.error('Delete error:', err);
    res.status(500).json({ success: false, message: 'Server error during delete' });
  }
});

module.exports = router;
