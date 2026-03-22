// src/services/calorie.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const todayStr = () => new Date().toISOString().split('T')[0];

// ── Helper: calculate BMR-based targets from user profile ────────────────────
const calcTargetsFromProfile = (user) => {
  const { weight, height, age, fitnessGoal } = user;
  const bmr = (10 * weight) + (4.9 * height) - (5 * age) + 5;
  const tdee = Math.round(bmr * 1.55);
  const adj = { weight_loss: -500, muscle_gain: 300, endurance: 100, flexibility: 0 };
  const dailyCalories = Math.round(tdee + (adj[fitnessGoal] || 0));
  return {
    dailyCalories,
    protein: Math.round(weight * 1.8),
    carbs: Math.round((dailyCalories * 0.45) / 4),
    fats: Math.round((dailyCalories * 0.25) / 9),
    fiber: 30,
  };
};

// ── Get Goals ────────────────────────────────────────────────────────────────
const getGoals = async (uid) => {
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) throw Object.assign(new Error('User profile not found'), { statusCode: 404 });
  const user = userDoc.data();

  // Check for custom goals
  if (user.calorieGoals) return user.calorieGoals;

  // Check for latest nutrition plan
  const planSnap = await db.collection('nutrition').where('uid', '==', uid).get();
  if (!planSnap.empty) {
    const plans = planSnap.docs.map(d => d.data()).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const latest = plans[0];
    if (latest.macros) {
      return {
        dailyCalories: latest.macros.dailyCalories || latest.plan?.dailyCalories || 2000,
        protein: latest.macros.protein || 120,
        carbs: latest.macros.carbs || 200,
        fats: latest.macros.fats || 65,
        fiber: 30,
      };
    }
  }

  // Fallback: calculate from profile
  return calcTargetsFromProfile(user);
};

// ── Set Goals ────────────────────────────────────────────────────────────────
const setGoals = async (uid, { dailyCalories, protein, carbs, fats }) => {
  const goals = {
    dailyCalories: dailyCalories || 2000,
    protein: protein || 120,
    carbs: carbs || 200,
    fats: fats || 65,
    fiber: 30,
    updatedAt: new Date().toISOString(),
  };
  await db.collection('users').doc(uid).set({ calorieGoals: goals }, { merge: true });
  return goals;
};

// ── Dashboard ────────────────────────────────────────────────────────────────
const getDashboard = async (uid) => {
  const date = todayStr();

  // Parallel fetches
  const [goalsData, foodSnap, workoutSnap, hydrationSnap, userDoc] = await Promise.all([
    getGoals(uid),
    db.collection('foodLogs').where('uid', '==', uid).where('date', '==', date).get(),
    db.collection('workouts').where('uid', '==', uid).get(),
    db.collection('hydrationLogs').where('uid', '==', uid).where('date', '==', date).get(),
    db.collection('users').doc(uid).get(),
  ]);

  const user = userDoc.exists ? userDoc.data() : {};

  // Food consumed
  const foodLogs = foodSnap.docs.map(d => d.data());
  let consumed = 0, cProtein = 0, cCarbs = 0, cFats = 0, cFiber = 0;
  foodLogs.forEach(l => {
    const n = l.totalNutrition || {};
    consumed += n.calories || 0;
    cProtein += n.protein || 0;
    cCarbs += n.carbs || 0;
    cFats += n.fats || 0;
    cFiber += n.fiber || 0;
  });

  // Workouts burned (today only)
  const allWorkouts = workoutSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  const todayWorkouts = allWorkouts.filter(w => {
    if (!w.completed || !w.completedAt) return false;
    return w.completedAt.startsWith(date);
  });
  const totalBurned = todayWorkouts.reduce((s, w) => s + (w.plan?.estimatedCalories || 0), 0);
  const workoutNames = todayWorkouts.map(w => w.plan?.planName || w.planName || 'Workout');

  // Hydration
  const hydrationLogs = hydrationSnap.docs.map(d => d.data());
  const hydrationTotal = hydrationLogs.reduce((s, l) => s + (l.amount || 0), 0);
  let hydrationGoalMl = 2500;
  try {
    const hGoalDoc = await db.collection('hydrationGoals').doc(uid).get();
    if (hGoalDoc.exists) hydrationGoalMl = hGoalDoc.data().dailyGoalMl || 2500;
  } catch (_) {}

  // Calculations
  const net = consumed - totalBurned;
  const target = goalsData.dailyCalories;
  const remaining = target - net;
  const pct = target > 0 ? Math.round((net / target) * 100) : 0;
  const status = pct > 110 ? 'over' : (pct >= 90 ? 'on-track' : 'under');

  // AI Insight
  let aiInsight = '';
  try {
    const prompt = `User consumed ${consumed} kcal of ${target} kcal target today. Burned ${totalBurned} kcal through workouts. Macros: protein ${cProtein}g/${goalsData.protein}g target, carbs ${cCarbs}g/${goalsData.carbs}g target, fats ${cFats}g/${goalsData.fats}g target. Give a 2-3 sentence personalized insight. Mention if they should eat more or less. Include one Sri Lankan food suggestion relevant to their goal: ${user.fitnessGoal || 'general fitness'}.`;
    const resp = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: 'You are a friendly nutritionist. Keep it to 2-3 sentences.' },
        { role: 'user', content: prompt },
      ],
      max_tokens: 200,
      temperature: 0.7,
    });
    aiInsight = resp.choices[0].message.content.trim();
  } catch (e) {
    aiInsight = 'Keep tracking your meals! Try adding Sri Lankan dhal curry for a protein boost.';
  }

  return {
    date,
    calories: { consumed, burned: totalBurned, net, target, remaining, percentOfTarget: pct, status },
    macros: {
      consumed: { protein: cProtein, carbs: cCarbs, fats: cFats, fiber: cFiber },
      target: { protein: goalsData.protein, carbs: goalsData.carbs, fats: goalsData.fats, fiber: goalsData.fiber || 30 },
      percentages: {
        protein: goalsData.protein > 0 ? Math.round((cProtein / goalsData.protein) * 100) : 0,
        carbs: goalsData.carbs > 0 ? Math.round((cCarbs / goalsData.carbs) * 100) : 0,
        fats: goalsData.fats > 0 ? Math.round((cFats / goalsData.fats) * 100) : 0,
        fiber: 30 > 0 ? Math.round((cFiber / 30) * 100) : 0,
      },
    },
    workoutsSummary: { completedToday: todayWorkouts.length, totalCaloriesBurned: totalBurned, workoutNames },
    hydration: {
      totalMl: hydrationTotal,
      goalMl: hydrationGoalMl,
      percentComplete: hydrationGoalMl > 0 ? Math.min(100, Math.round((hydrationTotal / hydrationGoalMl) * 100)) : 0,
    },
    aiInsight,
  };
};

// ── Weekly ───────────────────────────────────────────────────────────────────
const getWeekly = async (uid) => {
  const today = new Date();
  const dates = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    dates.push(d.toISOString().split('T')[0]);
  }

  const goals = await getGoals(uid);

  // Fetch food logs for the week
  const foodSnap = await db.collection('foodLogs').where('uid', '==', uid).get();
  const allFoodLogs = foodSnap.docs.map(d => d.data()).filter(l => l.date >= dates[0] && l.date <= dates[6]);

  // Fetch workouts
  const workoutSnap = await db.collection('workouts').where('uid', '==', uid).get();
  const allWorkouts = workoutSnap.docs.map(d => d.data()).filter(w => w.completed && w.completedAt);

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const weeklyData = dates.map(date => {
    const dayFoodLogs = allFoodLogs.filter(l => l.date === date);
    const consumed = dayFoodLogs.reduce((s, l) => s + (l.totalNutrition?.calories || 0), 0);

    const dayWorkouts = allWorkouts.filter(w => w.completedAt && w.completedAt.startsWith(date));
    const burned = dayWorkouts.reduce((s, w) => s + (w.plan?.estimatedCalories || 0), 0);

    const net = consumed - burned;
    const pct = goals.dailyCalories > 0 ? Math.round((net / goals.dailyCalories) * 100) : 0;
    const d = new Date(date);

    return {
      date,
      dayName: dayNames[d.getDay()],
      consumed,
      burned,
      net,
      target: goals.dailyCalories,
      status: pct > 110 ? 'over' : (pct >= 90 ? 'on-track' : 'under'),
    };
  });

  const totals = weeklyData.reduce((a, d) => ({
    consumed: a.consumed + d.consumed,
    burned: a.burned + d.burned,
    net: a.net + d.net,
  }), { consumed: 0, burned: 0, net: 0 });

  const bestDay = weeklyData.reduce((best, d) => d.consumed > (best?.consumed || 0) ? d : best, weeklyData[0]);

  // AI insight
  let weeklyInsight = '';
  try {
    const summary = weeklyData.map(d => `${d.dayName}: consumed ${d.consumed}, burned ${d.burned}`).join('; ');
    const prompt = `Review this 7-day calorie data: ${summary}. Daily target: ${goals.dailyCalories} kcal. Give a 2-3 sentence personalized weekly insight. Include a Sri Lankan food tip. Be encouraging.`;
    const resp = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: 'You are a friendly nutritionist. 2-3 sentences max.' },
        { role: 'user', content: prompt },
      ],
      max_tokens: 200,
      temperature: 0.7,
    });
    weeklyInsight = resp.choices[0].message.content.trim();
  } catch (_) {
    weeklyInsight = 'Keep tracking consistently! Try a balanced Sri Lankan meal platter for optimal nutrition.';
  }

  return {
    weeklyData,
    weeklyAverages: {
      consumed: Math.round(totals.consumed / 7),
      burned: Math.round(totals.burned / 7),
      net: Math.round(totals.net / 7),
    },
    bestDay,
    weeklyInsight,
  };
};

module.exports = { getDashboard, getWeekly, getGoals, setGoals };
