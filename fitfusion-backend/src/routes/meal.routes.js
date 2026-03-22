// src/routes/meal.routes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyToken } = require('../middleware/auth.middleware');
const {
  scanMeal,
  addCustomMeal,
  getLibrary,
  logMeal,
  getDailyLog,
  getWeeklyReport,
  updateMeal,
  deleteMeal,
  toggleFavorite
} = require('../controllers/meal.controller');

// Configure multer to use memory storage
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// All meal routes are protected
router.use(verifyToken);

// Routes
router.post('/scan', upload.single('image'), scanMeal);
router.post('/add', addCustomMeal);
router.get('/library', getLibrary);
router.post('/log', logMeal);
router.get('/log/today', getDailyLog);
router.get('/report/weekly', getWeeklyReport);

// Dynamic routes need to be at the bottom to avoid conflicts
router.patch('/:mealId', updateMeal);
router.delete('/:mealId', deleteMeal);
router.patch('/:mealId/favorite', toggleFavorite);

module.exports = router;
