// src/routes/user.routes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { saveUserProfile, getUserProfile, uploadAvatar, getDailySummary } = require('../controllers/user.controller');
const { uploadAvatar: multerUploadAvatar } = require('../middleware/upload.middleware');

router.post('/profile', verifyToken, saveUserProfile);
router.get('/profile', verifyToken, getUserProfile);
router.get('/daily-summary', verifyToken, getDailySummary);

// Avatar upload route handling both multipart forms and JSON (for urls)
router.post('/profile/avatar', verifyToken, multerUploadAvatar.single('avatar'), uploadAvatar);

// Contact admin
const { contactAdmin, getMyMessages, memberReply } = require('../controllers/user.controller');
router.post('/contact-admin', verifyToken, contactAdmin);
router.get('/my-messages', verifyToken, getMyMessages);
router.post('/messages/:id/reply', verifyToken, memberReply);

module.exports = router;