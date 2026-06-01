const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Dairy = require('../models/Dairy');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_dairy_key';

// Super Admin Login
router.post('/super', (req, res) => {
  const { mobile, password } = req.body;
  if (mobile === '9549196262' && password === 'sunil6262') {
    const token = jwt.sign({ role: 'super' }, JWT_SECRET);
    return res.json({ success: true, token, role: 'super' });
  }
  res.status(401).json({ success: false, message: 'Invalid Super Admin credentials' });
});

// Owner Login
router.post('/owner', async (req, res) => {
  try {
    const { mobile, password } = req.body;
    const dairy = await Dairy.findOne({ mobile, password });
    if (!dairy) {
      return res.status(401).json({ success: false, message: 'Invalid Mobile or Password' });
    }
    const token = jwt.sign({ role: 'owner', dairyCode: dairy.code }, JWT_SECRET);
    res.json({ 
      success: true, 
      token, 
      role: 'owner', 
      dairyCode: dairy.code, 
      dairyName: dairy.name,
      fatFactor: dairy.fatFactor,
      snfFactor: dairy.snfFactor,
      workers: dairy.workers instanceof Map ? Object.fromEntries(dairy.workers) : dairy.workers
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Worker Login
router.post('/worker', async (req, res) => {
  try {
    const { dairyCode, workerPin } = req.body;
    const dairy = await Dairy.findOne({ code: new RegExp(`^${dairyCode}$`, 'i') });
    if (!dairy) {
      return res.status(401).json({ success: false, message: 'Invalid Dairy Code' });
    }
    const workerName = dairy.workers.get(workerPin);
    if (!workerName) {
      return res.status(401).json({ success: false, message: 'Invalid Worker PIN' });
    }
    const token = jwt.sign({ role: 'worker', dairyCode: dairy.code }, JWT_SECRET);
    res.json({ 
      success: true, 
      token, 
      role: 'worker', 
      dairyCode: dairy.code, 
      dairyName: dairy.name, 
      workerName,
      fatFactor: dairy.fatFactor,
      snfFactor: dairy.snfFactor 
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Create/Seed Dairy (For Super Admin)
router.post('/register', async (req, res) => {
  try {
    const { code, name, mobile, password, workers } = req.body;
    const existing = await Dairy.findOne({ $or: [{ code }, { mobile }] });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Dairy code or mobile already exists' });
    }
    const dairy = new Dairy({ code, name, mobile, password, workers });
    await dairy.save();
    res.json({ success: true, message: 'Dairy registered successfully', dairy });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get all dairies (For Super Admin)
router.get('/dairies', async (req, res) => {
  try {
    const dairies = await Dairy.find();
    res.json({ success: true, dairies });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update dairy
router.put('/dairy/:code', async (req, res) => {
  try {
    const { name, mobile, password } = req.body;
    const updateData = {};
    if (name) updateData.name = name;
    if (mobile && mobile !== 'N/A') updateData.mobile = mobile;
    if (password) updateData.password = password;

    const dairy = await Dairy.findOneAndUpdate(
      { code: req.params.code },
      { $set: updateData },
      { new: true }
    );
    if (!dairy) return res.status(404).json({ success: false, message: 'Dairy not found' });
    res.json({ success: true, dairy });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete dairy
router.delete('/dairy/:code', async (req, res) => {
  try {
    const dairy = await Dairy.findOneAndDelete({ code: req.params.code });
    if (!dairy) return res.status(404).json({ success: false, message: 'Dairy not found' });
    res.json({ success: true, message: 'Dairy deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Register Worker
router.post('/dairy/:code/worker', async (req, res) => {
  try {
    const { pin, name } = req.body;
    const dairy = await Dairy.findOne({ code: req.params.code });
    if (!dairy) return res.status(404).json({ success: false, message: 'Dairy not found' });
    
    if (dairy.workers && dairy.workers.has(pin)) {
      return res.status(400).json({ success: false, message: 'इस PIN का वर्कर पहले से मौजूद है!' });
    }

    dairy.workers.set(pin, name);
    await dairy.save();
    res.json({ success: true, message: 'Worker added', workers: dairy.workers instanceof Map ? Object.fromEntries(dairy.workers) : dairy.workers });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete Worker
router.delete('/dairy/:code/worker/:pin', async (req, res) => {
  try {
    const { code, pin } = req.params;
    const dairy = await Dairy.findOne({ code });
    if (!dairy) return res.status(404).json({ success: false, message: 'Dairy not found' });
    
    if (dairy.workers.has(pin)) {
      dairy.workers.delete(pin);
      await dairy.save();
      res.json({ success: true, message: 'Worker deleted', workers: dairy.workers instanceof Map ? Object.fromEntries(dairy.workers) : dairy.workers });
    } else {
      res.status(404).json({ success: false, message: 'Worker not found' });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update Rate Settings
router.post('/dairy/:code/rate', async (req, res) => {
  try {
    const { fatFactor, snfFactor } = req.body;
    const dairy = await Dairy.findOne({ code: req.params.code });
    if (!dairy) return res.status(404).json({ success: false, message: 'Dairy not found' });
    
    dairy.fatFactor = fatFactor;
    dairy.snfFactor = snfFactor;
    await dairy.save();
    res.json({ success: true, message: 'Rate settings updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
