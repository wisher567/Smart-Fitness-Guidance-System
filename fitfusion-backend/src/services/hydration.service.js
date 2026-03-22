// src/services/hydration.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// ── Helpers ──────────────────────────────────────────────────────────────────
const todayStr = (date) => {
  const d = date ? new Date(date) : new Date();
  return d.toISOString().split('T')[0]; // YYYY-MM-DD
};

const buildDailySummary = (logs, goalMl) => {
  const totalMl = logs.reduce((sum, l) => sum + (l.amount || 0), 0);
  const remaining = Math.max(0, goalMl - totalMl);
  return {
    totalMl,
    goalMl,
    remaining,
    percentComplete: goalMl > 0 ? Math.min(100, Math.round((totalMl / goalMl) * 100)) : 0,
    goalReached: totalMl >= goalMl,
    logsCount: logs.length,
  };
};

// ── Get Goal ─────────────────────────────────────────────────────────────────
const getGoal = async (uid) => {
  const doc = await db.collection('hydrationGoals').doc(uid).get();
  if (doc.exists) return doc.data();
  return { uid, dailyGoalMl: 2500, reminderEnabled: false, reminderIntervalHours: 2 };
};

// ── Set Goal ─────────────────────────────────────────────────────────────────
const setGoal = async (uid, { dailyGoalMl, reminderEnabled, reminderIntervalHours }) => {
  const data = {
    uid,
    dailyGoalMl: dailyGoalMl || 2500,
    reminderEnabled: reminderEnabled ?? false,
    reminderIntervalHours: reminderIntervalHours || 2,
    updatedAt: new Date().toISOString(),
  };
  await db.collection('hydrationGoals').doc(uid).set(data, { merge: true });
  return data;
};

// ── Log Water ────────────────────────────────────────────────────────────────
const logWater = async (uid, { amount, type, icon, note }) => {
  if (!amount || amount <= 0) throw Object.assign(new Error('Amount must be positive'), { statusCode: 400 });

  const now = new Date();
  const date = todayStr();

  const logDoc = {
    uid,
    amount: Number(amount),
    type: type || 'water',
    icon: icon || '💧',
    loggedAt: now.toISOString(),
    date,
    note: note || '',
  };

  const ref = await db.collection('hydrationLogs').add(logDoc);

  // Get today's logs to compute summary
  const todaySnap = await db.collection('hydrationLogs')
    .where('uid', '==', uid)
    .where('date', '==', date)
    .get();

  const todayLogs = todaySnap.docs.map(d => d.data());
  const goal = await getGoal(uid);
  const summary = buildDailySummary(todayLogs, goal.dailyGoalMl);

  // Check if goal was JUST reached (previous total was below, now above)
  let pointsEarned = 0;
  const previousTotal = summary.totalMl - amount;
  if (summary.goalReached && previousTotal < goal.dailyGoalMl) {
    // Award points
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    const currentPoints = userDoc.exists ? (userDoc.data().points || 0) : 0;
    await userRef.set({ points: currentPoints + 20 }, { merge: true });
    pointsEarned = 20;
  }

  return {
    logId: ref.id,
    log: { ...logDoc, id: ref.id },
    dailySummary: { date, ...summary, pointsEarned },
  };
};

// ── Get Today ────────────────────────────────────────────────────────────────
const getTodayLogs = async (uid, date) => {
  const targetDate = todayStr(date);

  const snap = await db.collection('hydrationLogs')
    .where('uid', '==', uid)
    .where('date', '==', targetDate)
    .get();

  const logs = snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.loggedAt) - new Date(a.loggedAt));

  const goal = await getGoal(uid);
  const summary = buildDailySummary(logs, goal.dailyGoalMl);

  // Breakdown by type
  const breakdown = { water: 0, juice: 0, tea: 0, coffee: 0, other: 0 };
  for (const log of logs) {
    const t = log.type || 'other';
    breakdown[t] = (breakdown[t] || 0) + (log.amount || 0);
  }

  return {
    date: targetDate,
    goal: { dailyGoalMl: goal.dailyGoalMl, reminderEnabled: goal.reminderEnabled },
    logs,
    summary: { ...summary, breakdown },
  };
};

// ── Get Weekly ───────────────────────────────────────────────────────────────
const getWeeklyData = async (uid) => {
  const goal = await getGoal(uid);
  const today = new Date();
  const dates = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    dates.push(todayStr(d));
  }

  // Fetch all logs for the last 7 days
  const snap = await db.collection('hydrationLogs')
    .where('uid', '==', uid)
    .where('date', '>=', dates[0])
    .where('date', '<=', dates[6])
    .get();

  const allLogs = snap.docs.map(d => d.data());

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const weeklyData = dates.map(date => {
    const dayLogs = allLogs.filter(l => l.date === date);
    const totalMl = dayLogs.reduce((s, l) => s + (l.amount || 0), 0);
    const d = new Date(date);
    return {
      date,
      dayName: dayNames[d.getDay()],
      totalMl,
      goalMl: goal.dailyGoalMl,
      percentComplete: goal.dailyGoalMl > 0 ? Math.min(100, Math.round((totalMl / goal.dailyGoalMl) * 100)) : 0,
      goalReached: totalMl >= goal.dailyGoalMl,
    };
  });

  const weeklyAverage = Math.round(weeklyData.reduce((s, d) => s + d.totalMl, 0) / 7);
  const bestDay = weeklyData.reduce((best, d) => d.totalMl > (best?.totalMl || 0) ? d : best, weeklyData[0]);
  const goalAchievedDays = weeklyData.filter(d => d.goalReached).length;

  // AI Insight via Groq
  let weeklyInsight = '';
  try {
    const amounts = weeklyData.map(d => `${d.dayName}: ${d.totalMl}ml`).join(', ');
    const prompt = `User drank these amounts of water over 7 days: ${amounts}. Their daily goal is ${goal.dailyGoalMl}ml. They achieved their goal ${goalAchievedDays} out of 7 days. Give a 2-3 sentence personalized hydration insight with one specific Sri Lankan tip (e.g. coconut water, king coconut). Be encouraging.`;

    const response = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: 'You are a friendly fitness hydration coach. Keep responses to 2-3 sentences max.' },
        { role: 'user', content: prompt },
      ],
      max_tokens: 200,
      temperature: 0.7,
    });
    weeklyInsight = response.choices[0].message.content.trim();
  } catch (e) {
    console.error('Groq hydration insight error:', e.message);
    weeklyInsight = 'Keep up your hydration habits! Try adding king coconut water for natural electrolytes.';
  }

  return { weeklyData, weeklyAverage, bestDay, goalAchievedDays, weeklyInsight };
};

// ── Delete Log ───────────────────────────────────────────────────────────────
const deleteLog = async (uid, logId) => {
  const ref = db.collection('hydrationLogs').doc(logId);
  const doc = await ref.get();
  if (!doc.exists) throw Object.assign(new Error('Log not found'), { statusCode: 404 });
  if (doc.data().uid !== uid) throw Object.assign(new Error('Unauthorized'), { statusCode: 403 });

  const date = doc.data().date;
  await ref.delete();

  // Return updated summary
  const snap = await db.collection('hydrationLogs')
    .where('uid', '==', uid)
    .where('date', '==', date)
    .get();

  const logs = snap.docs.map(d => d.data());
  const goal = await getGoal(uid);
  return { date, ...buildDailySummary(logs, goal.dailyGoalMl) };
};

module.exports = { logWater, getTodayLogs, getWeeklyData, getGoal, setGoal, deleteLog };
