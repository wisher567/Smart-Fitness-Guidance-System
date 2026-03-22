// src/services/workout.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const getRecommendation = async (uid) => {
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) throw new Error('User profile not found. Please create your profile first.');
  const user = userDoc.data();

  // Get recent workouts
  const historySnap = await db
    .collection('workouts')
    .where('uid', '==', uid)
    .get();

  const recentWorkouts = historySnap.docs
    .map(d => d.data())
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 5)
    .map(d => d.planName || '');

  const prompt = `
You are an expert fitness trainer. Generate a personalized workout plan as valid JSON only.
No extra text, no markdown, no backticks — pure JSON only.

User Profile:
- Name: ${user.name}
- Age: ${user.age}
- BMI: ${user.bmi} (Weight: ${user.weight}kg, Height: ${user.height}cm)
- Fitness Goal: ${user.fitnessGoal}
- Fitness Level: ${user.fitnessLevel}
- Medical Conditions: ${(user.medicalConditions || []).join(', ') || 'none'}
- Recent workouts to AVOID repeating: ${recentWorkouts.join(', ') || 'none'}

Return ONLY this JSON structure:
{
  "planName": "string",
  "goal": "string",
  "totalDuration": "string",
  "estimatedCalories": number,
  "difficulty": "Beginner | Intermediate | Advanced",
  "warmup": [
    { "exercise": "string", "duration": "string", "instructions": "string" }
  ],
  "mainWorkout": [
    {
      "exercise": "string",
      "sets": number,
      "reps": "string",
      "rest": "string",
      "muscleGroup": "string",
      "instructions": "string",
      "modification": "string"
    }
  ],
  "cooldown": [
    { "exercise": "string", "duration": "string", "instructions": "string" }
  ],
  "tips": ["string", "string", "string"],
  "nutrition": {
    "preworkout": "string",
    "postworkout": "string",
    "hydration": "string"
  }
}`;

  // Call Groq
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: 'You are a fitness expert. Always respond with valid JSON only. No markdown, no backticks.' },
      { role: 'user', content: prompt }
    ],
    max_tokens: 2000,
    temperature: 0.7
  });

  let responseText = response.choices[0].message.content.trim();
  responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

  let plan;
  try {
    plan = JSON.parse(responseText);
  } catch (err) {
    throw new Error('AI returned invalid format. Please try again.');
  }

  const workoutDoc = {
    uid,
    planName: plan.planName,
    plan,
    completed: false,
    createdAt: new Date().toISOString(),
    completedAt: null,
    rating: null
  };

  const saved = await db.collection('workouts').add(workoutDoc);

  await db.collection('users').doc(uid).set(
    { points: (user.points || 0) + 10 },
    { merge: true }
  );

  return {
    workoutId: saved.id,
    plan,
    pointsEarned: 10,
    totalPoints: (user.points || 0) + 10
  };
};

const completeWorkout = async (uid, workoutId, rating) => {
  const workoutRef = db.collection('workouts').doc(workoutId);
  const workoutDoc = await workoutRef.get();

  if (!workoutDoc.exists) throw new Error('Workout not found');
  if (workoutDoc.data().uid !== uid) throw new Error('Unauthorized');

  await workoutRef.update({
    completed: true,
    completedAt: new Date().toISOString(),
    rating: rating || null,
    'plan.estimatedCalories': workoutDoc.data().plan?.estimatedCalories || 0,
  });

  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.data();
  const newPoints = (user.points || 0) + 50;

  const completedSnap = await db
    .collection('workouts')
    .where('uid', '==', uid)
    .where('completed', '==', true)
    .get();

  const badges = [...(user.badges || [])];
  const totalCompleted = completedSnap.size;

  if (totalCompleted === 1 && !badges.includes('first_workout')) badges.push('first_workout');
  if (totalCompleted === 7 && !badges.includes('week_warrior')) badges.push('week_warrior');
  if (totalCompleted === 30 && !badges.includes('monthly_champion')) badges.push('monthly_champion');

  await db.collection('users').doc(uid).update({ points: newPoints, badges });

  return {
    success: true,
    pointsEarned: 50,
    totalPoints: newPoints,
    newBadges: badges.filter(b => !(user.badges || []).includes(b))
  };
};

const getWorkoutHistory = async (uid) => {
  const snap = await db
    .collection('workouts')
    .where('uid', '==', uid)
    .get();

  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 20);
};

const logCompletedWorkout = async (uid, data) => {
  const { exerciseName, sets, reps, caloriesBurned, durationSeconds, rating, completedAt } = data;
  
  const workoutDoc = {
    uid,
    planName: exerciseName || 'Quick Workout',
    plan: {
      planName: exerciseName || 'Quick Workout',
      estimatedCalories: caloriesBurned || 0,
      totalDuration: `${Math.round((durationSeconds || 0)/60)} min`
    },
    completed: true,
    createdAt: completedAt || new Date().toISOString(),
    completedAt: completedAt || new Date().toISOString(),
    rating: rating || null,
    sets,
    reps,
    durationSeconds
  };

  const saved = await db.collection('workouts').add(workoutDoc);

  // Award points
  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.exists ? userDoc.data() : {};
  const newPoints = (user.points || 0) + 50;

  // Badge logic
  const completedSnap = await db.collection('workouts').where('uid', '==', uid).where('completed', '==', true).get();
  const badges = [...(user.badges || [])];
  const totalCompleted = completedSnap.size;

  if (totalCompleted === 1 && !badges.includes('first_workout')) badges.push('first_workout');
  if (totalCompleted === 7 && !badges.includes('week_warrior')) badges.push('week_warrior');
  if (totalCompleted === 30 && !badges.includes('monthly_champion')) badges.push('monthly_champion');

  await db.collection('users').doc(uid).set({ points: newPoints, badges }, { merge: true });

  return {
    success: true,
    workoutId: saved.id,
    pointsEarned: 50,
    totalPoints: newPoints,
    newBadges: badges.filter(b => !(user.badges || []).includes(b))
  };
};

module.exports = { getRecommendation, completeWorkout, getWorkoutHistory, logCompletedWorkout };
