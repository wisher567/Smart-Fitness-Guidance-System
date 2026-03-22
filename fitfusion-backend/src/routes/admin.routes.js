// src/routes/admin.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken, verifyAdmin } = require('../middleware/auth.middleware');
const { 
  getRevenueStats, 
  getMemberStats, 
  addTrainer, 
  getTrainers, 
  updateTrainer,
  deleteTrainer,
  updatePlan, 
  deletePlan,
  getDashboardStats,
  getAllMembers,
  getMemberById,
  getAllPayments,
  getAllPlans,
  createPlan,
  getAllClasses,
  createClass,
  updateClass,
  deleteClass,
  createAlert,
  getAllAlerts,
  getMyAlerts,
  getAlertById,
  updateAlert,
  deleteAlert,
  assignTrainer,
  createTrainerRequest,
  getAllRequests,
  getMyRequests,
  updateRequest,
  getAllClassesForMembers,
  enrollInClass,
  cancelEnrollment,
  getAllMessages,
  replyToMessage
} = require('../controllers/admin.controller');

// Adding token verification to admin routes
router.get('/dashboard', verifyToken, getDashboardStats);
router.get('/members', verifyToken, getAllMembers);
router.get('/members/:uid', verifyToken, getMemberById);
router.patch('/members/:uid', verifyToken, verifyAdmin, assignTrainer);
router.get('/payments', verifyToken, getAllPayments);
router.get('/plans', verifyToken, getAllPlans);
router.post('/plans', verifyToken, createPlan);
router.get('/classes', verifyToken, getAllClasses);
router.get('/classes/all', verifyToken, getAllClassesForMembers);
router.post('/classes', verifyToken, createClass);
router.post('/classes/:id/enroll', verifyToken, enrollInClass);
router.delete('/classes/:id/enroll', verifyToken, cancelEnrollment);
router.patch('/classes/:id', verifyToken, updateClass);
router.delete('/classes/:id', verifyToken, deleteClass);
// Equipment Alerts Routes
router.post('/alerts', verifyToken, createAlert);
router.get('/alerts/my', verifyToken, getMyAlerts);
router.get('/alerts', verifyToken, verifyAdmin, getAllAlerts);
router.get('/alerts/:id', verifyToken, verifyAdmin, getAlertById);
router.patch('/alerts/:id', verifyToken, verifyAdmin, updateAlert);
router.delete('/alerts/:id', verifyToken, verifyAdmin, deleteAlert);
router.get('/stats/revenue', verifyToken, getRevenueStats);
router.get('/stats/members', verifyToken, getMemberStats);
router.post('/trainers', verifyToken, addTrainer);
router.get('/trainers', verifyToken, getTrainers);
router.patch('/trainers/:id', verifyToken, updateTrainer);
router.delete('/trainers/:id', verifyToken, deleteTrainer);
router.patch('/plans/:id', verifyToken, updatePlan);
router.delete('/plans/:id', verifyToken, deletePlan);
// Trainer Requests
router.get('/trainer-requests/my', verifyToken, getMyRequests);
router.get('/trainer-requests', verifyToken, verifyAdmin, getAllRequests);
router.post('/trainer-requests', verifyToken, createTrainerRequest);
router.patch('/trainer-requests/:id', verifyToken, verifyAdmin, updateRequest);

// Messages endpoints
router.get('/messages', verifyToken, verifyAdmin, getAllMessages);
router.patch('/messages/:id', verifyToken, verifyAdmin, replyToMessage);

module.exports = router;
