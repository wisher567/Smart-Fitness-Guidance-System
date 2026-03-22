// src/controllers/meal.controller.js
const mealService = require('../services/meal.service');
const asyncHandler = require('../utils/asyncHandler');

// ─────────────────────────────────────────
// FEATURE 1: SCAN MEAL FROM IMAGE
// ─────────────────────────────────────────
// POST /api/meals/scan
const scanMeal = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  if (!req.file) {
    return res.status(400).json({ success: false, error: 'Image file is required' });
  }

  const category = req.body.category || 'custom';
  const result = await mealService.scanMeal(uid, req.file.buffer, req.file.mimetype, category);
  
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 2: ADD CUSTOM MEAL MANUALLY
// ─────────────────────────────────────────
// POST /api/meals/add
const addCustomMeal = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const { name, category, items, tags, isFavorite } = req.body;

  if (!name || !category) {
    return res.status(400).json({ success: false, error: 'Name and category are required' });
  }

  const validCategories = ['breakfast', 'lunch', 'dinner', 'snack', 'custom'];
  if (!validCategories.includes(category)) {
    return res.status(400).json({ success: false, error: `Invalid category. Must be one of: ${validCategories.join(', ')}` });
  }

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, error: 'At least one item is required' });
  }

  const result = await mealService.addCustomMeal(uid, { name, category, items, tags, isFavorite });
  
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 3: GET USER FOOD LIBRARY
// ─────────────────────────────────────────
// GET /api/meals/library
const getLibrary = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const queryParams = {
    category: req.query.category,
    favorite: req.query.favorite,
    tag: req.query.tag,
    search: req.query.search
  };

  const result = await mealService.getLibrary(uid, queryParams);
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 4: LOG A MEAL
// ─────────────────────────────────────────
// POST /api/meals/log
const logMeal = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const { mealId, category, notes } = req.body;

  if (!mealId) {
    return res.status(400).json({ success: false, error: 'mealId is required' });
  }

  // category is optional for override
  const result = await mealService.logMeal(uid, { mealId, category, notes });
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 5: GET DAILY FOOD LOG
// ─────────────────────────────────────────
// GET /api/meals/log/today
const getDailyLog = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const dateStr = req.query.date; // optional
  const result = await mealService.getDailyLog(uid, dateStr);
  
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 6: GET WEEKLY NUTRITION REPORT
// ─────────────────────────────────────────
// GET /api/meals/report/weekly
const getWeeklyReport = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const result = await mealService.getWeeklyReport(uid);
  
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 7: UPDATE MEAL
// ─────────────────────────────────────────
// PATCH /api/meals/:mealId
const updateMeal = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const mealId = req.params.mealId;
  const data = req.body;

  if (data.category) {
    const validCategories = ['breakfast', 'lunch', 'dinner', 'snack', 'custom'];
    if (!validCategories.includes(data.category)) {
      return res.status(400).json({ success: false, error: `Invalid category. Must be one of: ${validCategories.join(', ')}` });
    }
  }

  const result = await mealService.updateMeal(uid, mealId, data);
  res.json({ success: true, meal: result });
});

// ─────────────────────────────────────────
// FEATURE 8: DELETE MEAL
// ─────────────────────────────────────────
// DELETE /api/meals/:mealId
const deleteMeal = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const mealId = req.params.mealId;

  const result = await mealService.deleteMeal(uid, mealId);
  res.json({ success: true, ...result });
});

// ─────────────────────────────────────────
// FEATURE 9: TOGGLE FAVORITE
// ─────────────────────────────────────────
// PATCH /api/meals/:mealId/favorite
const toggleFavorite = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const mealId = req.params.mealId;

  const result = await mealService.toggleFavorite(uid, mealId);
  res.json({ success: true, ...result });
});

module.exports = {
  scanMeal,
  addCustomMeal,
  getLibrary,
  logMeal,
  getDailyLog,
  getWeeklyReport,
  updateMeal,
  deleteMeal,
  toggleFavorite
};
