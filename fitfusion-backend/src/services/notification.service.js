// src/services/notification.service.js
const { db } = require('../config/firebase');

// Send notification to user
const sendNotification = async (uid, notification) => {
  const notificationData = {
    uid,
    title: notification.title,
    message: notification.message,
    type: notification.type || 'info', // info, success, warning, error
    read: false,
    createdAt: new Date().toISOString()
  };
  
  await db.collection('notifications').add(notificationData);
  return notificationData;
};

// Get user notifications
const getUserNotifications = async (uid, limit = 20) => {
  const snap = await db
    .collection('notifications')
    .where('uid', '==', uid)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Mark notification as read
const markAsRead = async (notificationId) => {
  await db.collection('notifications').doc(notificationId).update({
    read: true,
    readAt: new Date().toISOString()
  });
};

// Delete notification
const deleteNotification = async (notificationId) => {
  await db.collection('notifications').doc(notificationId).delete();
};

module.exports = {
  sendNotification,
  getUserNotifications,
  markAsRead,
  deleteNotification
};
