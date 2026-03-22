// src/controllers/leaderboard.controller.js
const { getLeaderboard } = require('../services/leaderboard.service');

const get = async (req, res) => {
  try {
    const result = await getLeaderboard(req.user.uid);
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { get };