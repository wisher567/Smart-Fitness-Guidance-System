// src/controllers/workout.controller.js
const {
  getRecommendation,
  completeWorkout,
  getWorkoutHistory,
  logCompletedWorkout
} = require('../services/workout.service');
const asyncHandler = require('../utils/asyncHandler');
const Groq = require('groq-sdk');
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// GET /api/workouts/recommend
const recommend = asyncHandler(async (req, res) => {
  const result = await getRecommendation(req.user.uid);
  res.json({ success: true, ...result });
});

// POST /api/workouts/:id/complete
const complete = asyncHandler(async (req, res) => {
  const { rating } = req.body;
  const result = await completeWorkout(req.user.uid, req.params.id, rating);
  res.json(result);
});

// GET /api/workouts/history
const history = asyncHandler(async (req, res) => {
  const workouts = await getWorkoutHistory(req.user.uid);
  res.json({ success: true, workouts });
});

// POST /api/workouts/instructions
const getInstructions = asyncHandler(async (req, res) => {
  const { exerciseName, difficulty, sets, reps } = req.body;

  const completion = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: 'You are a certified personal trainer. Return only valid JSON.',
      },
      {
        role: 'user',
        content: `Give step by step instructions for ${exerciseName}. Difficulty: ${difficulty}, Sets: ${sets}, Reps: ${reps}. Return ONLY a JSON array of 5 strings. Each string = one clear instruction about form, breathing, common mistakes. No markdown, no backticks, pure JSON array only.`,
      },
    ],
    temperature: 0.4,
    max_tokens: 512,
  });

  const raw = completion.choices[0]?.message?.content?.trim() ?? '[]';
  let instructions;
  try {
    instructions = JSON.parse(raw);
    if (!Array.isArray(instructions)) throw new Error('not array');
  } catch {
    instructions = [
      `Start in the correct position for ${exerciseName} with a neutral spine.`,
      'Engage your core and breathe in before the movement begins.',
      'Perform the movement with controlled speed — no jerking.',
      'Exhale as you complete the concentric phase of the exercise.',
      'Return to the starting position slowly and repeat for all reps.',
    ];
  }

  res.json({ success: true, instructions });
});

// POST /api/workouts/log
const logCompleted = asyncHandler(async (req, res) => {
  const result = await logCompletedWorkout(req.user.uid, req.body);
  res.json(result);
});

module.exports = { recommend, complete, history, getInstructions, logCompleted };