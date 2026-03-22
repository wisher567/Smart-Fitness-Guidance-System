// src/routes/leaderboard.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { get } = require('../controllers/leaderboard.controller');

router.get('/', verifyToken, get);

module.exports = router;