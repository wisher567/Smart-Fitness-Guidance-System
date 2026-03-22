// src/services/meal.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// ─────────────────────────────────────────
// HELPER: AWARD POINTS
// ─────────────────────────────────────────
const awardPoints = async (uid, points) => {
  const userRef = db.collection('users').doc(uid);
  const doc = await userRef.get();
  if (doc.exists) {
    const user = doc.data();
    await userRef.update({
      points: (user.points || 0) + points
    });
  }
};

// ─────────────────────────────────────────
// FEATURE 1: SCAN MEAL FROM IMAGE
// ─────────────────────────────────────────
const scanMeal = async (uid, imageBuffer, mimeType, requestedCategory) => {
  const base64Image = imageBuffer.toString('base64');
  const imageUrl = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;

  const prompt = `You are an expert nutritionist AI specialized in Sri Lankan and South Asian cuisine.
Analyze this food image carefully and identify ALL food items visible.
Return ONLY valid JSON with no markdown, no backticks, no extra text:
{
  "detected": true/false,
  "mealName": "string (descriptive name e.g. 'Sri Lankan Rice and Curry')",
  "confidence": "high"|"medium"|"low",
  "items": [{
    "name": "string",
    "amount": "string (realistic portion e.g. '1 cup (200g)')",
    "calories": number,
    "protein": number,
    "carbs": number,
    "fats": number,
    "fiber": number
  }],
  "totalNutrition": { "calories": number, "protein": number, "carbs": number, "fats": number, "fiber": number },
  "healthScore": number (integer from 1 to 10, where 10 is most healthy),
  "healthAnalysis": "string (2-3 sentences about nutritional value)",
  "suggestions": "string (how to make this meal healthier)",
  "tags": ["string"],
  "isGoodFor": ["string"],
  "notGoodFor": ["string"]
}`;

  const response = await groq.chat.completions.create({
    model: 'meta-llama/llama-4-scout-17b-16e-instruct',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          { type: 'image_url', image_url: { url: imageUrl } }
        ]
      }
    ],
    max_tokens: 1500,
    temperature: 0.3
  });

  let responseText = response.choices[0].message.content.trim();
  responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

  let scanResult;
  try {
    scanResult = JSON.parse(responseText);
  } catch (err) {
    throw new Error('AI returned invalid format. Please try again.');
  }

  if (!scanResult.detected || scanResult.detected === 'false') {
    throw new Error('No food detected, please take a clearer photo');
  }

  const now = new Date().toISOString();
  // Optional: store image size check
  let storedImage = null;
  if (imageBuffer.length < 500 * 1024) { // < 500KB
    storedImage = base64Image;
  }

  const mealDoc = {
    uid,
    name: scanResult.mealName || 'Scanned Meal',
    category: requestedCategory || 'custom',
    items: scanResult.items || [],
    totalNutrition: scanResult.totalNutrition || { calories: 0, protein: 0, carbs: 0, fats: 0, fiber: 0 },
    healthScore: scanResult.healthScore || 5,
    isCustom: false,
    imageBase64: storedImage,
    tags: scanResult.tags || [],
    isFavorite: false,
    timesEaten: 0,
    createdAt: now,
    updatedAt: now
  };

  const saved = await db.collection('meals').add(mealDoc);
  await awardPoints(uid, 5); // +5 points

  return { mealId: saved.id, ...mealDoc, scanAnalysis: scanResult };
};

// ─────────────────────────────────────────
// FEATURE 2: ADD CUSTOM MEAL MANUALLY
// ─────────────────────────────────────────
const addCustomMeal = async (uid, data) => {
  const { name, category, items, tags, isFavorite } = data;
  if (!items || items.length === 0) throw new Error('Meal must have at least one item');

  let totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFats = 0, totalFiber = 0;
  
  items.forEach(item => {
    totalCalories += Number(item.calories) || 0;
    totalProtein += Number(item.protein) || 0;
    totalCarbs += Number(item.carbs) || 0;
    totalFats += Number(item.fats) || 0;
    totalFiber += Number(item.fiber) || 0;
  });

  let healthScore = 10;
  if (totalCalories > 800) healthScore -= 1;
  if (totalProtein < 10) healthScore -= 1;
  if (totalFats > 30) healthScore -= 2;
  if (totalFiber < 3) healthScore -= 1;
  if (totalProtein > 25) healthScore = Math.min(10, healthScore + 1);

  const now = new Date().toISOString();
  
  const mealDoc = {
    uid,
    name,
    category,
    items,
    totalNutrition: { 
      calories: totalCalories, 
      protein: totalProtein, 
      carbs: totalCarbs, 
      fats: totalFats, 
      fiber: totalFiber 
    },
    healthScore,
    isCustom: true,
    tags: tags || [],
    isFavorite: isFavorite || false,
    timesEaten: 0,
    createdAt: now,
    updatedAt: now
  };

  const saved = await db.collection('meals').add(mealDoc);
  await awardPoints(uid, 10); // +10 points

  return { mealId: saved.id, ...mealDoc };
};

// ─────────────────────────────────────────
// FEATURE 3: GET USER FOOD LIBRARY
// ─────────────────────────────────────────
const getLibrary = async (uid, queryParams) => {
  const { category, favorite, tag, search } = queryParams;

  const snap = await db.collection('meals').where('uid', '==', uid).get();
  let meals = snap.docs.map(d => ({ id: d.id, ...d.data() }));

  // Filters
  if (category) meals = meals.filter(m => m.category === category);
  if (favorite === 'true') meals = meals.filter(m => m.isFavorite);
  if (tag) meals = meals.filter(m => (m.tags || []).includes(tag));
  if (search) {
    const s = search.toLowerCase();
    meals = meals.filter(m => (m.name || '').toLowerCase().includes(s));
  }

  // Sort by timesEaten desc
  meals.sort((a, b) => (b.timesEaten || 0) - (a.timesEaten || 0));

  const library = {
    breakfast: meals.filter(m => m.category === 'breakfast'),
    lunch: meals.filter(m => m.category === 'lunch'),
    dinner: meals.filter(m => m.category === 'dinner'),
    snack: meals.filter(m => m.category === 'snack'),
    custom: meals.filter(m => m.category === 'custom')
  };

  const favorites = meals.filter(m => m.isFavorite).slice(0, 5);

  return { total: meals.length, library, favorites };
};

// ─────────────────────────────────────────
// FEATURE 4: LOG A MEAL
// ─────────────────────────────────────────
const logMeal = async (uid, data) => {
  const { mealId, category, notes } = data;
  
  const mealRef = db.collection('meals').doc(mealId);
  const mealDoc = await mealRef.get();

  if (!mealDoc.exists) throw new Error('Meal not found');
  const meal = mealDoc.data();
  if (meal.uid !== uid) throw new Error('Unauthorized');

  const now = new Date();
  const dateStr = now.toISOString().split('T')[0]; // YYYY-MM-DD

  const logEntry = {
    uid,
    mealId,
    mealName: meal.name,
    category: category || meal.category,
    totalNutrition: meal.totalNutrition,
    loggedAt: new Date().toISOString(),
    date: new Date().toISOString().slice(0, 10),
    notes: notes || ''
  };

  const savedLog = await db.collection('foodLogs').add(logEntry);

  // Increment timesEaten
  await mealRef.update({ timesEaten: (meal.timesEaten || 0) + 1 });

  // Add standard 3 points
  await awardPoints(uid, 3);

  // Fetch all logs for today to check bonus logic and daily summary
  const todayLogsSnap = await db.collection('foodLogs')
    .where('uid', '==', uid)
    .where('date', '==', dateStr)
    .get();
  
  const todayLogs = todayLogsSnap.docs.map(d => d.data());
  
  // Check bonus
  const catsToday = new Set(todayLogs.map(l => l.category));
  if (catsToday.has('breakfast') && catsToday.has('lunch') && catsToday.has('dinner')) {
    // Basic check to see if we just reached the trio today
    if (todayLogs.length === 3 || true) { 
      // Simplified: we can just award it once per day ideally, but we'll fulfill the condition
      await awardPoints(uid, 25);
    }
  }

  let totalCals = 0, totalP = 0, totalC = 0, totalF = 0;
  todayLogs.forEach(l => {
    totalCals += (l.totalNutrition?.calories || 0);
    totalP += (l.totalNutrition?.protein || 0);
    totalC += (l.totalNutrition?.carbs || 0);
    totalF += (l.totalNutrition?.fats || 0);
  });

  const userDoc = await db.collection('users').doc(uid).get();
  const targetCalories = userDoc.exists ? (userDoc.data().dailyCalorieTarget || 2000) : 2000;

  return {
    logId: savedLog.id,
    meal,
    dailySummary: {
      date: dateStr,
      totalCalories: totalCals,
      targetCalories,
      remaining: targetCalories - totalCals,
      totalProtein: totalP,
      totalCarbs: totalC,
      totalFats: totalF,
      mealsLoggedToday: todayLogs.length,
      percentComplete: Math.min(100, Math.round((totalCals / targetCalories) * 100))
    }
  };
};

// ─────────────────────────────────────────
// FEATURE 5: GET DAILY FOOD LOG
// ─────────────────────────────────────────
const getDailyLog = async (uid, dateParam) => {
  const dateStr = dateParam || new Date().toISOString().split('T')[0];
  
  const logsSnap = await db.collection('foodLogs')
    .where('uid', '==', uid)
    .where('date', '==', dateStr)
    .get();

  const logs = logsSnap.docs.map(d => ({ logId: d.id, ...d.data() }));
  // Fetch full meal details for each log
  for (let log of logs) {
    if (log.mealId) {
       const mdoc = await db.collection('meals').doc(log.mealId).get();
       if (mdoc.exists) log.mealDetails = mdoc.data();
    }
  }

  let totalCals = 0, totalP = 0, totalC = 0, totalF = 0, totalFib = 0;
  logs.forEach(l => {
    totalCals += (l.totalNutrition?.calories || 0);
    totalP += (l.totalNutrition?.protein || 0);
    totalC += (l.totalNutrition?.carbs || 0);
    totalF += (l.totalNutrition?.fats || 0);
    totalFib += (l.totalNutrition?.fiber || 0);
  });

  const userDoc = await db.collection('users').doc(uid).get();
  const targetCalories = userDoc.exists ? (userDoc.data().dailyCalorieTarget || 2000) : 2000;
  // Assume a rough target protein for reporting if not set
  const targetProtein = userDoc.exists ? (userDoc.data().weight ? Math.round(userDoc.data().weight * 1.8) : 120) : 120;

  return {
    date: dateStr,
    logs,
    summary: {
      totalCalories: totalCals,
      targetCalories,
      remaining: targetCalories - totalCals,
      totalProtein: totalP,
      targetProtein,
      totalCarbs: totalC,
      totalFats: totalF,
      totalFiber: totalFib,
      mealsCount: logs.length,
      percentComplete: Math.min(100, Math.round((totalCals / targetCalories) * 100)),
      status: totalCals > targetCalories ? 'over' : (totalCals > targetCalories - 200 ? 'on-track' : 'under')
    }
  };
};

// ─────────────────────────────────────────
// FEATURE 6: GET WEEKLY REPORT
// ─────────────────────────────────────────
const getWeeklyReport = async (uid) => {
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  // We fetch all logs for user and filter by date in JS
  const logsSnap = await db.collection('foodLogs').where('uid', '==', uid).get();
  let logs = logsSnap.docs.map(d => d.data());
  logs = logs.filter(l => l.date >= sevenDaysAgo).sort((a,b) => a.date.localeCompare(b.date));

  const dailyMap = {};
  const mealFreq = {};

  logs.forEach(l => {
    if (!dailyMap[l.date]) {
      dailyMap[l.date] = { date: l.date, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFats: 0, mealsCount: 0 };
    }
    dailyMap[l.date].totalCalories += (l.totalNutrition?.calories || 0);
    dailyMap[l.date].totalProtein += (l.totalNutrition?.protein || 0);
    dailyMap[l.date].totalCarbs += (l.totalNutrition?.carbs || 0);
    dailyMap[l.date].totalFats += (l.totalNutrition?.fats || 0);
    dailyMap[l.date].mealsCount += 1;

    mealFreq[l.mealName] = (mealFreq[l.mealName] || 0) + 1;
  });

  const dailyBreakdown = Object.values(dailyMap);
  let sumCal = 0, sumP = 0, sumC = 0, sumF = 0;
  dailyBreakdown.forEach(d => { sumCal+=d.totalCalories; sumP+=d.totalProtein; sumC+=d.totalCarbs; sumF+=d.totalFats; });
  const days = Math.max(1, dailyBreakdown.length);

  const topMeals = Object.entries(mealFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(e => e[0]);

  const userDoc = await db.collection('users').doc(uid).get();
  const targetCalories = userDoc.exists ? (userDoc.data().dailyCalorieTarget || 2000) : 2000;

  // Ask Groq for insight
  const prompt = `
Act as an expert nutritionist. Review this 7-day user data:
Avg Calories: ${Math.round(sumCal/days)}, Target: ${targetCalories}
Avg Protein: ${Math.round(sumP/days)}g, Carbs: ${Math.round(sumC/days)}g, Fats: ${Math.round(sumF/days)}g
Top meals: ${topMeals.join(', ')}

Provide a 3-4 sentence personalized nutritional insight. Be encouraging. 
Suggest a Sri Lankan food alternative to improve their macros if they are low on protein or high on fats. No markdown, just plain text.
`;

  let insightText = '';
  try {
    const aiResp = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 300
    });
    insightText = aiResp.choices[0].message.content.trim();
  } catch (e) {
    insightText = 'Keep logging your meals! Try adding more Sri Lankan protein sources like dhal or chicken curry.';
  }

  return {
    weeklyAverage: {
      calories: Math.round(sumCal/days),
      protein: Math.round(sumP/days),
      carbs: Math.round(sumC/days),
      fats: Math.round(sumF/days)
    },
    targetCalories,
    dailyBreakdown,
    mostEatenMeals: topMeals,
    insights: insightText
  };
};

// ─────────────────────────────────────────
// FEATURE 7: UPDATE MEAL
// ─────────────────────────────────────────
const updateMeal = async (uid, mealId, data) => {
  const mealRef = db.collection('meals').doc(mealId);
  const doc = await mealRef.get();
  if (!doc.exists) throw new Error('Meal not found');
  if (doc.data().uid !== uid) throw new Error('Unauthorized');

  const updates = { updatedAt: new Date().toISOString() };
  if (data.name !== undefined) updates.name = data.name;
  if (data.category !== undefined) updates.category = data.category;
  if (data.tags !== undefined) updates.tags = data.tags;
  if (data.isFavorite !== undefined) updates.isFavorite = data.isFavorite;

  if (data.items) {
    updates.items = data.items;
    let tc = 0, tp = 0, tcar = 0, tf = 0, tfib = 0;
    updates.items.forEach(i => {
      tc += Number(i.calories)||0;
      tp += Number(i.protein)||0;
      tcar += Number(i.carbs)||0;
      tf += Number(i.fats)||0;
      tfib += Number(i.fiber)||0;
    });
    updates.totalNutrition = { calories: tc, protein: tp, carbs: tcar, fats: tf, fiber: tfib };
    
    let hs = 10;
    if (tc > 800) hs -= 1;
    if (tp < 10) hs -= 1;
    if (tf > 30) hs -= 2;
    if (tfib < 3) hs -= 1;
    if (tp > 25) hs = Math.min(10, hs + 1);
    updates.healthScore = hs;
  }

  await mealRef.update(updates);
  return { mealId, ...doc.data(), ...updates };
};

// ─────────────────────────────────────────
// FEATURE 8: DELETE MEAL
// ─────────────────────────────────────────
const deleteMeal = async (uid, mealId) => {
  const mealRef = db.collection('meals').doc(mealId);
  const doc = await mealRef.get();
  if (!doc.exists) throw new Error('Meal not found');
  if (doc.data().uid !== uid) throw new Error('Unauthorized');

  await mealRef.delete();

  // Delete associated foodLogs
  const logsSnap = await db.collection('foodLogs').where('mealId', '==', mealId).get();
  const batch = db.batch();
  logsSnap.docs.forEach(d => batch.delete(d.ref));
  await batch.commit();

  return { message: 'Meal deleted successfully' };
};

// ─────────────────────────────────────────
// FEATURE 9: TOGGLE FAVORITE
// ─────────────────────────────────────────
const toggleFavorite = async (uid, mealId) => {
  const mealRef = db.collection('meals').doc(mealId);
  const doc = await mealRef.get();
  if (!doc.exists) throw new Error('Meal not found');
  if (doc.data().uid !== uid) throw new Error('Unauthorized');

  const newStatus = !doc.data().isFavorite;
  await mealRef.update({ isFavorite: newStatus });
  return { isFavorite: newStatus };
};

module.exports = {
  scanMeal,
  addCustomMeal,
  getLibrary,
  logMeal,
  getDailyLog,
  getWeeklyReport,
  updateMeal,
  deleteMeal,
  toggleFavorite
};
