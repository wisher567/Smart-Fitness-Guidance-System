// src/routes/nutrition.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { generatePlan, latest, log, history } = require('../controllers/nutrition.controller');

router.get('/plan',       verifyToken, generatePlan);
router.get('/latest',     verifyToken, latest);
router.post('/:id/log',   verifyToken, log);
router.get('/history',    verifyToken, history);

module.exports = router;