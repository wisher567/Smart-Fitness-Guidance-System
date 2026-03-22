// src/routes/posture.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const axios = require('axios');
const FormData = require('form-data');
const multer = require('multer');
const asyncHandler = require('../utils/asyncHandler');

// Store image in memory temporarily
const upload = multer({ storage: multer.memoryStorage() });

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

// POST /api/posture/analyze
router.post('/analyze', verifyToken, upload.single('image'), asyncHandler(async (req, res) => {
  const { exercise } = req.body;

  if (!req.file) {
    return res.status(400).json({ error: 'Image is required' });
  }

  // Forward image to Python service
  const formData = new FormData();
  formData.append('exercise', exercise);
  formData.append('image', req.file.buffer, {
    filename: 'frame.jpg',
    contentType: req.file.mimetype
  });

  const response = await axios.post(
    `${AI_SERVICE_URL}/posture/analyze`,
    formData,
    { headers: formData.getHeaders() }
  );

  // Award points for using posture detection
  const { db } = require('../config/firebase');
  const uid = req.user.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.data();

  if (response.data.detected) {
    await db.collection('users').doc(uid).set(
      { points: (user.points || 0) + 3 },
      { merge: true }
    );
  }

  res.json({
    ...response.data,
    pointsEarned: response.data.detected ? 3 : 0
  });
}));

// GET /api/posture/exercises
router.get('/exercises', verifyToken, asyncHandler(async (req, res) => {
  const response = await axios.get(`${AI_SERVICE_URL}/posture/exercises`);
  res.json(response.data);
}));

// ── Real-time routes ────────────────────────────────────────────────────────

// POST /api/posture/realtime/frame
// Called by Flutter every 500ms with a base64 camera frame
router.post('/realtime/frame', verifyToken, asyncHandler(async (req, res) => {
  const { image, exercise, timestamp } = req.body;

  if (!image || !exercise) {
    return res.status(400).json({ error: 'image and exercise are required' });
  }

  try {
    const response = await axios.post(
      `${AI_SERVICE_URL}/realtime/frame`,
      { image, exercise, timestamp: timestamp || Date.now() },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 5000   // 5s — tight timeout for real-time feel
      }
    );
    res.json(response.data);
  } catch (err) {
    // Timeout: return "not detected" instead of crashing
    if (err.code === 'ECONNABORTED') {
      return res.json({ detected: false, error: 'Analysis timeout - frame skipped' });
    }
    throw err;  // Let asyncHandler handle other errors
  }
}));

// GET /api/posture/realtime/status
router.get('/realtime/status', verifyToken, asyncHandler(async (req, res) => {
  try {
    const response = await axios.get(`${AI_SERVICE_URL}/realtime/status`, { timeout: 3000 });
    res.json(response.data);
  } catch (err) {
    res.status(503).json({ status: 'offline', error: 'AI service not reachable' });
  }
}));

module.exports = router;