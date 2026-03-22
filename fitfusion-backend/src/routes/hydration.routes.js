// src/routes/hydration.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const ctrl = require('../controllers/hydration.controller');

router.post('/log', verifyToken, ctrl.log);
router.get('/today', verifyToken, ctrl.today);
router.get('/weekly', verifyToken, ctrl.weekly);
router.get('/goal', verifyToken, ctrl.getGoal);
router.post('/goal', verifyToken, ctrl.setGoal);
router.delete('/log/:logId', verifyToken, ctrl.deleteLog);

module.exports = router;
