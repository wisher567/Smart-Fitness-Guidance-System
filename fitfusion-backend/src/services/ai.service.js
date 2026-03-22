// src/services/ai.service.js
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Generic AI text generation
const generateText = async (prompt, model = 'gemini-2.0-flash') => {
  const aiModel = genAI.getGenerativeModel({ model });
  const result = await aiModel.generateContent(prompt);
  return result.response.text();
};

// AI chat with history
const chatWithHistory = async (messages, model = 'gemini-2.0-flash') => {
  const aiModel = genAI.getGenerativeModel({ model });
  const chat = aiModel.startChat({ history: messages });
  return chat;
};

module.exports = {
  generateText,
  chatWithHistory,
  genAI
};
