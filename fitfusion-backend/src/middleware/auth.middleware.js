// src/middleware/auth.middleware.js
const { auth } = require('../config/firebase');

const verifyToken = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = await auth.verifyIdToken(token);
    req.user = decoded; // contains uid, email etc
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};
const verifyAdmin = async (req, res, next) => {
  try {
    const { db } = require('../config/firebase');
    const doc = await db.collection('users').doc(req.user.uid).get();
    if (!doc.exists || doc.data().role !== 'admin') {
      return res.status(403).json({ error: 'Requires admin privileges' });
    }
    next();
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

module.exports = { verifyToken, verifyAdmin };