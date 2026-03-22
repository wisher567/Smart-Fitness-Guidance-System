// src/controllers/payment.controller.js
const paymentService = require('../services/payment.service');

const getPlans = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await paymentService.getPlans(uid);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const subscribe = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { planId, cardDetails } = req.body;
    if (!planId || !cardDetails || !cardDetails.last4) {
      return res.status(400).json({ error: 'planId and cardDetails.last4 are required' });
    }
    const result = await paymentService.subscribe(uid, planId, cardDetails);
    res.json({ success: true, ...result });
  } catch (err) {
    const isDeclined = err.message === 'Payment declined';
    res.status(isDeclined ? 400 : 500).json({ error: err.message });
  }
};

const getSubscription = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await paymentService.getSubscription(uid);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getHistory = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await paymentService.getHistory(uid);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getPayment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { paymentId } = req.params;
    const result = await paymentService.getPayment(uid, paymentId);
    res.json(result);
  } catch (err) {
    const status = err.message === 'Unauthorized' ? 403 : err.message === 'Payment not found' ? 404 : 500;
    res.status(status).json({ error: err.message });
  }
};

const cancelSubscription = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await paymentService.cancelSubscription(uid);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getSavedCards = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await paymentService.getSavedCards(uid);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const addCard = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { last4, brand, expiryMonth, expiryYear, cardholderName, isDefault } = req.body;
    if (!last4 || !expiryMonth || !expiryYear || !cardholderName) {
      return res.status(400).json({ error: 'last4, expiryMonth, expiryYear, cardholderName are required' });
    }
    const result = await paymentService.addCard(uid, { last4, brand, expiryMonth, expiryYear, cardholderName, isDefault });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const deleteCard = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { cardId } = req.params;
    const result = await paymentService.deleteCard(uid, cardId);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getPlans,
  subscribe,
  getSubscription,
  getHistory,
  getPayment,
  cancelSubscription,
  getSavedCards,
  addCard,
  deleteCard,
};
