// src/controllers/calorie.controller.js
const calorieService = require('../services/calorie.service');
const asyncHandler = require('../utils/asyncHandler');

const dashboard = asyncHandler(async (req, res) => {
  const result = await calorieService.getDashboard(req.user.uid);
  res.json({ success: true, ...result });
});

const weekly = asyncHandler(async (req, res) => {
  const result = await calorieService.getWeekly(req.user.uid);
  res.json({ success: true, ...result });
});

const getGoals = asyncHandler(async (req, res) => {
  const goals = await calorieService.getGoals(req.user.uid);
  res.json({ success: true, goals });
});

const setGoals = asyncHandler(async (req, res) => {
  const goals = await calorieService.setGoals(req.user.uid, req.body);
  res.json({ success: true, goals });
});

module.exports = { dashboard, weekly, getGoals, setGoals };
