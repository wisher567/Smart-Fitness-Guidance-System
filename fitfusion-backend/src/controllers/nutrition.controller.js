// src/controllers/nutrition.controller.js
const {
  generateMealPlan,
  logMeal,
  getNutritionHistory,
  getLatestPlan
} = require('../services/nutrition.service');
const asyncHandler = require('../utils/asyncHandler');

// GET /api/nutrition/plan  — generate new plan
const generatePlan = asyncHandler(async (req, res) => {
  const result = await generateMealPlan(req.user.uid);
  res.json({ success: true, ...result });
});

// GET /api/nutrition/latest  — get most recent plan
const latest = asyncHandler(async (req, res) => {
  const plan = await getLatestPlan(req.user.uid);
  if (!plan) return res.status(404).json({ error: 'No nutrition plan found. Generate one first.' });
  res.json({ success: true, plan });
});

// POST /api/nutrition/:id/log  — log a meal
const log = asyncHandler(async (req, res) => {
  const { mealType, actualCalories } = req.body;

  if (!mealType || !actualCalories) {
    return res.status(400).json({ error: 'mealType and actualCalories are required' });
  }

  const result = await logMeal(
    req.user.uid,
    req.params.id,
    mealType,
    actualCalories
  );
  res.json(result);
});

// GET /api/nutrition/history
const history = asyncHandler(async (req, res) => {
  const plans = await getNutritionHistory(req.user.uid);
  res.json({ success: true, plans });
});

module.exports = { generatePlan, latest, log, history };