// src/controllers/user.controller.js
const { db } = require('../config/firebase');
const asyncHandler = require('../utils/asyncHandler');

const { sendWelcomeEmail, sendContactAdminEmail, sendContactConfirmationEmail } = require('../services/email.service');

// Create or update user profile
const saveUserProfile = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const { name, age, weight, height, fitnessGoal, fitnessLevel, medicalConditions, phone } = req.body;

  // Auto-calculate BMI
  const heightM = height / 100;
  const bmi = +(weight / (heightM * heightM)).toFixed(1);

  const userRef = db.collection('users').doc(uid);
  const doc = await userRef.get();

  const userData = {
    uid,
    name,
    age,
    weight,
    height,
    bmi,
    fitnessGoal,      // 'weight_loss' | 'muscle_gain' | 'endurance'
    fitnessLevel,     // 'beginner' | 'intermediate' | 'advanced'
    medicalConditions: medicalConditions || [],
    phone: phone || '',
    updatedAt: new Date().toISOString()
  };

  // Only initialize these fields if the user is completely new
  const isNewUser = !doc.exists;
  if (isNewUser) {
    userData.points = 0;
    userData.badges = [];
    userData.role = 'member';
    userData.createdAt = new Date().toISOString();
  }

  // Firestore: set() creates or overwrites document (merge: true keeps existing fields)
  await userRef.set(userData, { merge: true });

  if (isNewUser) {
    const emailToSend = userData.email || req.user.email;
    if (emailToSend) {
      sendWelcomeEmail({ ...userData, email: emailToSend }).catch(err => 
        console.error('Welcome email failed:', err.message)
      );
    }
  }

  // Get finalized document
  const finalDoc = await userRef.get();
  res.json({ success: true, user: { id: finalDoc.id, ...finalDoc.data() } });
});

// Get user profile — auto-creates a minimal stub if first sign-in
const getUserProfile = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  const userRef = db.collection('users').doc(uid);
  const doc = await userRef.get();

  if (!doc.exists) {
    // First-time sign-in: Firebase user exists but no Firestore doc yet.
    // Create a minimal stub so the home page can load without 404.
    const stub = {
      uid,
      name: req.user.name || req.user.email?.split('@')[0] || 'User',
      email: req.user.email || '',
      photoUrl: req.user.picture || null,
      points: 0,
      badges: [],
      role: 'member',
      profileComplete: false,   // flag so frontend can redirect to onboarding if needed
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    await userRef.set(stub);
    return res.json({ success: true, user: stub });
  }

  res.json({ success: true, user: doc.data() });
});

// Upload user avatar
const uploadAvatar = asyncHandler(async (req, res) => {
  const uid = req.user.uid;
  
  // If the user uploads an image, req.file will be populated by multer
  // If the user sends a string URL (for preset avatars or removing avatar), we expect req.body.photoUrl
  let photoUrl = req.body.photoUrl;

  if (req.file) {
    const filename = req.file.filename;
    // Construct the public URL
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    photoUrl = `${protocol}://${req.get('host')}/uploads/avatars/${filename}`;
  } else if (!photoUrl && req.body.remove === 'true') {
    photoUrl = null; // Client wants to remove the avatar
  } else if (!photoUrl) {
    return res.status(400).json({ error: 'No avatar image or URL provided' });
  }

  // Update Firestore user document
  await db.collection('users').doc(uid).set({ photoUrl, updatedAt: new Date().toISOString() }, { merge: true });

  res.json({ success: true, photoUrl });
});

const getDailySummary = async (req, res) => {
  try {
    const uid = req.user.uid;
    const today = new Date().toISOString().slice(0, 10);

    // Run all queries in parallel
    const [userDoc, workoutsSnap, foodLogsSnap, nutritionSnap] = 
      await Promise.all([
        db.collection('users').doc(uid).get(),

        // Today's completed workouts
        db.collection('workouts')
          .where('uid', '==', uid)
          .where('completed', '==', true)
          .get(),

        // Today's food logs
        db.collection('foodLogs')
          .where('uid', '==', uid)
          .where('date', '==', today)
          .get(),

        // Latest nutrition plan
        db.collection('nutrition')
          .where('uid', '==', uid)
          .get(),
      ]);

    const user = userDoc.exists ? userDoc.data() : {};

    // ── Calculate calorie targets from user profile ──
    const weight = user.weight || 70;
    const height = user.height || 170;
    const age    = user.age    || 25;
    const goal   = user.fitnessGoal || 'weight_loss';

    const bmr  = (10 * weight) + (4.9 * height) - (5 * age) + 5;
    const tdee = Math.round(bmr * 1.55);

    const goalCalories = {
      weight_loss:    Math.round(tdee - 500),
      muscle_gain:    Math.round(tdee + 300),
      endurance:      Math.round(tdee + 100),
      flexibility:    tdee,
      general_fitness: tdee,
    };

    const targetCalories = goalCalories[goal] || tdee;
    const targetProtein  = Math.round(weight * 1.8);
    const targetCarbs    = Math.round((targetCalories * 0.45) / 4);
    const targetFats     = Math.round((targetCalories * 0.25) / 9);
    const targetFiber    = 30;

    // ── Override with nutrition plan if exists ──
    let planTargetCalories = targetCalories;
    let planTargetProtein  = targetProtein;
    let planTargetCarbs    = targetCarbs;
    let planTargetFats     = targetFats;

    if (!nutritionSnap.empty) {
      const plans = nutritionSnap.docs
        .map(d => d.data())
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      const latest = plans[0];
      if (latest?.macros) {
        planTargetCalories = latest.macros.dailyCalories || targetCalories;
        planTargetProtein  = latest.macros.protein       || targetProtein;
        planTargetCarbs    = latest.macros.carbs         || targetCarbs;
        planTargetFats     = latest.macros.fats          || targetFats;
      }
    }

    // ── Calculate today's workouts burned calories ──
    const allWorkouts = workoutsSnap.docs.map(d => d.data());
    const todayWorkouts = allWorkouts.filter(w => {
      if (!w.completedAt) return false;
      return w.completedAt.slice(0, 10) === today;
    });

    const totalCaloriesBurned = todayWorkouts.reduce(
      (sum, w) => sum + (w.plan?.estimatedCalories || 0), 0
    );

    const completedWorkoutsList = todayWorkouts.map(w => ({
      exerciseName: w.planName || 'Workout',
      caloriesBurned: w.plan?.estimatedCalories || 0,
      completedAt: w.completedAt,
    }));

    // ── Calculate today's food consumed ──
    const foodLogs = foodLogsSnap.docs.map(d => d.data());

    const totalCaloriesConsumed = foodLogs.reduce(
      (sum, log) => sum + (log.totalNutrition?.calories || 0), 0
    );
    const totalProtein = foodLogs.reduce(
      (sum, log) => sum + (log.totalNutrition?.protein || 0), 0
    );
    const totalCarbs = foodLogs.reduce(
      (sum, log) => sum + (log.totalNutrition?.carbs || 0), 0
    );
    const totalFats = foodLogs.reduce(
      (sum, log) => sum + (log.totalNutrition?.fats || 0), 0
    );
    const totalFiber = foodLogs.reduce(
      (sum, log) => sum + (log.totalNutrition?.fiber || 0), 0
    );

    // ── Calculate remaining based on goal ──
    let caloriesRemaining;
    if (goal === 'weight_loss') {
      caloriesRemaining = planTargetCalories - totalCaloriesConsumed + totalCaloriesBurned;
    } else if (goal === 'muscle_gain') {
      caloriesRemaining = planTargetCalories - totalCaloriesConsumed;
    } else {
      caloriesRemaining = planTargetCalories - totalCaloriesConsumed;
    }

    const netCalories = totalCaloriesConsumed - totalCaloriesBurned;

    // ── Build response ──
    res.json({
      success: true,
      summary: {
        date: today,
        fitnessGoal: goal,
        targetCalories:  planTargetCalories,
        targetProtein:   planTargetProtein,
        targetCarbs:     planTargetCarbs,
        targetFats:      planTargetFats,
        targetFiber,
        totalCaloriesConsumed: Math.round(totalCaloriesConsumed),
        totalProtein:          Math.round(totalProtein * 10) / 10,
        totalCarbs:            Math.round(totalCarbs   * 10) / 10,
        totalFats:             Math.round(totalFats    * 10) / 10,
        totalFiber:            Math.round(totalFiber   * 10) / 10,
        mealsCount:            foodLogs.length,
        totalCaloriesBurned,
        completedWorkouts: completedWorkoutsList,
        workoutsCount: todayWorkouts.length,
        caloriesRemaining: Math.max(0, Math.round(caloriesRemaining)),
        netCalories:       Math.round(netCalories),
        percentComplete:   planTargetCalories > 0
          ? Math.round((totalCaloriesConsumed / planTargetCalories) * 100)
          : 0,
        status: totalCaloriesConsumed < planTargetCalories * 0.8
          ? 'under'
          : totalCaloriesConsumed <= planTargetCalories * 1.1
          ? 'on-track'
          : 'over',
      }
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const contactAdmin = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { subject, message, category } = req.body;

    if (!subject || !message) {
      return res.status(400).json({ 
        error: 'Subject and message are required' 
      });
    }

    // Get member info
    const userDoc = await db.collection('users').doc(uid).get();
    const member  = userDoc.data();

    // Save to Firestore
    const ticket = {
      uid,
      memberName:  member.name,
      memberEmail: member.email || '',
      subject,
      message,
      category:   category || 'general',
      status:     'open',
      adminReply: '',
      createdAt:  new Date().toISOString(),
      updatedAt:  new Date().toISOString(),
    };

    const saved = await db.collection('contactMessages').add(ticket);

    // Email to admin
    sendContactAdminEmail(member, ticket).catch(err =>
      console.error('Admin contact email failed:', err.message)
    );

    // Confirmation email to member
    sendContactConfirmationEmail(member, ticket).catch(err =>
      console.error('Confirmation email failed:', err.message)
    );

    res.json({
      success: true,
      ticketId: saved.id,
      message:  'Message sent! Admin will reply within 24 hours.',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get member's own messages
const getMyMessages = async (req, res) => {
  try {
    const snap = await db.collection('contactMessages')
      .where('uid', '==', req.user.uid)
      .get();

    const messages = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({ success: true, messages });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Member replies to an admin response (thread continuation)
const memberReply = async (req, res) => {
  try {
    const { reply } = req.body;
    if (!reply || !reply.trim()) {
      return res.status(400).json({ error: 'Reply text is required' });
    }

    const msgRef = db.collection('contactMessages').doc(req.params.id);
    const msgDoc = await msgRef.get();

    if (!msgDoc.exists) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Verify ownership
    const msg = msgDoc.data();
    if (msg.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const replyEntry = {
      from: 'member',
      text: reply.trim(),
      createdAt: new Date().toISOString(),
    };

    const existingReplies = msg.replies || [];
    existingReplies.push(replyEntry);

    await msgRef.update({
      replies: existingReplies,
      status: 'open',           // reopen so admin sees the new message
      updatedAt: new Date().toISOString(),
    });

    res.json({ success: true, message: 'Reply sent successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { saveUserProfile, getUserProfile, uploadAvatar, getDailySummary, contactAdmin, getMyMessages, memberReply };