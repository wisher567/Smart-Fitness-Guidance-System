// src/routes/chatbot.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { sendMessage, getHistory, clearHistory } = require('../controllers/chatbot.controller');

router.post('/message',  verifyToken, sendMessage);
router.get('/history',   verifyToken, getHistory);
router.delete('/history', verifyToken, clearHistory);

module.exports = router;