// src/controllers/hydration.controller.js
const hydrationService = require('../services/hydration.service');
const asyncHandler = require('../utils/asyncHandler');

const log = asyncHandler(async (req, res) => {
  const result = await hydrationService.logWater(req.user.uid, req.body);
  res.json({ success: true, ...result });
});

const today = asyncHandler(async (req, res) => {
  const result = await hydrationService.getTodayLogs(req.user.uid, req.query.date);
  res.json({ success: true, ...result });
});

const weekly = asyncHandler(async (req, res) => {
  const result = await hydrationService.getWeeklyData(req.user.uid);
  res.json({ success: true, ...result });
});

const getGoal = asyncHandler(async (req, res) => {
  const goal = await hydrationService.getGoal(req.user.uid);
  res.json({ success: true, goal });
});

const setGoal = asyncHandler(async (req, res) => {
  const goal = await hydrationService.setGoal(req.user.uid, req.body);
  res.json({ success: true, goal });
});

const deleteLog = asyncHandler(async (req, res) => {
  const summary = await hydrationService.deleteLog(req.user.uid, req.params.logId);
  res.json({ success: true, dailySummary: summary });
});

module.exports = { log, today, weekly, getGoal, setGoal, deleteLog };
