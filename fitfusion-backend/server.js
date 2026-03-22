// server.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();

// CORS configuration
const corsOptions = {
  origin: true,
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(helmet());
app.use(express.json({ strict: false }));
app.use(express.urlencoded({ extended: true }));

app.use('/api/users', require('./src/routes/user.routes'));
app.use('/api/chatbot', require('./src/routes/chatbot.routes'));
app.use('/api/workouts', require('./src/routes/workout.routes'));
app.use('/api/nutrition', require('./src/routes/nutrition.routes'));
app.use('/api/posture', require('./src/routes/posture.routes'));
app.use('/api/leaderboard', require('./src/routes/leaderboard.routes'));
app.use('/api/meals', require('./src/routes/meal.routes'));
app.use('/api/hydration', require('./src/routes/hydration.routes'));
app.use('/api/calories', require('./src/routes/calorie.routes'));
app.use('/api/payments', require('./src/routes/payment.routes'));
app.use('/api/admin', require('./src/routes/admin.routes'));
app.use('/api/trainer', require('./src/routes/trainer.routes'));

// Serve uploads statically
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'FitFusion backend running ✅' });
});

// TEMPORARY test route - no auth
app.post('/api/test-chatbot', async (req, res) => {
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const maxRetries = 3;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await model.generateContent(req.body.message);
      return res.json({ success: true, reply: result.response.text() });
    } catch (err) {
      const retryMatch = err.message.match(/retryDelay.*?(\d+)s/i);
      if (retryMatch && attempt < maxRetries - 1) {
        const waitSec = Math.min(parseInt(retryMatch[1]) + 2, 40);
        console.log(`Rate limited, retrying in ${waitSec}s (attempt ${attempt + 1})...`);
        await new Promise(r => setTimeout(r, waitSec * 1000));
      } else {
        return res.status(500).json({ error: err.message });
      }
    }
  }
});

// Error handling middleware (must be last)
const { errorHandler, notFoundHandler } = require('./src/middleware/error.middleware');
app.use(notFoundHandler);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));