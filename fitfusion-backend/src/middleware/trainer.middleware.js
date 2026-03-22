const { db } = require('../config/firebase');

const verifyTrainer = async (req, res, next) => {
  try {
    const uid     = req.user.uid;
    const userDoc = await db.collection('users').doc(uid).get();
    const role    = userDoc.data()?.role;
    
    if (role !== 'trainer' && role !== 'admin') {
      return res.status(403).json({ 
        error: 'Access denied. Trainers only.' 
      });
    }
    req.trainer = userDoc.data();
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { verifyTrainer };
