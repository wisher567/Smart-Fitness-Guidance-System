// src/routes/payment.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const ctrl = require('../controllers/payment.controller');

router.get('/plans', verifyToken, ctrl.getPlans);
router.post('/subscribe', verifyToken, ctrl.subscribe);
router.get('/subscription', verifyToken, ctrl.getSubscription);
router.get('/history', verifyToken, ctrl.getHistory);
router.get('/history/:paymentId', verifyToken, ctrl.getPayment);
router.post('/cancel', verifyToken, ctrl.cancelSubscription);
router.get('/cards', verifyToken, ctrl.getSavedCards);
router.post('/cards', verifyToken, ctrl.addCard);
router.delete('/cards/:cardId', verifyToken, ctrl.deleteCard);

module.exports = router;
