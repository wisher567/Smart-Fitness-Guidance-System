// src/controllers/chatbot.controller.js
const { chat, getChatHistory, clearChatHistory } = require('../services/chatbot.service');
const asyncHandler = require('../utils/asyncHandler');

// POST /api/chatbot/message
const sendMessage = asyncHandler(async (req, res) => {
  const { message } = req.body;
  const uid = req.user.uid;

  if (!message || message.trim() === '') {
    return res.status(400).json({ 
      success: false,
      error: 'Message cannot be empty' 
    });
  }

  const response = await chat(uid, message.trim());
  
  res.json({ 
    success: true, 
    ...response 
  });
});

// GET /api/chatbot/history
const getHistory = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const history = await getChatHistory(uid);
  
  res.json({ 
    success: true, 
    count: history.length,
    history 
  });
});

// DELETE /api/chatbot/history
const clearHistory = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const result = await clearChatHistory(uid);
  
  res.json({ 
    success: true, 
    ...result 
  });
});

module.exports = { sendMessage, getHistory, clearHistory };