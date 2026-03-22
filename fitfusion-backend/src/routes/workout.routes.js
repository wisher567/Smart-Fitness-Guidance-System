// src/routes/workout.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { recommend, complete, history, getInstructions, logCompleted } = require('../controllers/workout.controller');

router.get('/recommend', verifyToken, recommend);
router.post('/instructions', verifyToken, getInstructions);
router.post('/log', verifyToken, logCompleted);
router.post('/:id/complete', verifyToken, complete);
router.get('/history', verifyToken, history);

module.exports = router;