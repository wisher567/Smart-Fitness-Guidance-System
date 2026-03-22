// src/routes/calorie.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const ctrl = require('../controllers/calorie.controller');

router.get('/dashboard', verifyToken, ctrl.dashboard);
router.get('/weekly', verifyToken, ctrl.weekly);
router.get('/goals', verifyToken, ctrl.getGoals);
router.post('/goals', verifyToken, ctrl.setGoals);

module.exports = router;
