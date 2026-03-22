// src/services/nutrition.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const calculateCalories = (user) => {
  const { weight, height, age, fitnessGoal } = user;
  const bmr = (10 * weight) + (4.9 * height) - (5 * age) + 5;
  const tdee = Math.round(bmr * 1.55);
  const goalAdjustments = {
    weight_loss:  Math.round(tdee - 500),
    muscle_gain:  Math.round(tdee + 300),
    endurance:    Math.round(tdee + 100),
    flexibility:  tdee
  };
  const dailyCalories = goalAdjustments[fitnessGoal] || tdee;
  return {
    bmr: Math.round(bmr),
    tdee,
    dailyCalories,
    protein: Math.round(weight * 1.8),
    carbs: Math.round((dailyCalories * 0.45) / 4),
    fats: Math.round((dailyCalories * 0.25) / 9)
  };
};

const generateMealPlan = async (uid) => {
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) throw new Error('User profile not found.');
  const user = userDoc.data();
  const macros = calculateCalories(user);

  const prompt = `
You are an expert nutritionist. Generate a full day meal plan as valid JSON only.
No extra text, no markdown, no backticks — pure JSON only.

User Profile:
- Name: ${user.name}, Age: ${user.age}
- Weight: ${user.weight}kg, Height: ${user.height}cm, BMI: ${user.bmi}
- Goal: ${user.fitnessGoal}, Level: ${user.fitnessLevel}
- Medical Conditions: ${(user.medicalConditions || []).join(', ') || 'none'}
- Daily Calories: ${macros.dailyCalories} kcal
- Protein: ${macros.protein}g, Carbs: ${macros.carbs}g, Fats: ${macros.fats}g

Include Sri Lankan foods: rice, dhal curry, coconut sambol, gotukola,
jak fruit, hoppers, string hoppers, fish curry, chicken curry, pol roti.

Return ONLY this JSON:
{
  "planName": "string",
  "dailyCalories": number,
  "macros": { "protein": number, "carbs": number, "fats": number },
  "meals": {
    "breakfast": {
      "time": "string",
      "name": "string",
      "items": [
        {
          "food": "string",
          "amount": "string",
          "calories": number,
          "protein": number,
          "carbs": number,
          "fats": number,
          "sriLankanAlternative": "string or null"
        }
      ],
      "totalCalories": number,
      "instructions": "string"
    },
    "morningSnack": {},
    "lunch": {},
    "afternoonSnack": {},
    "dinner": {}
  },
  "hydration": { "dailyWaterIntake": "string", "tips": ["string"] },
  "supplements": [{ "name": "string", "timing": "string", "reason": "string", "optional": true }],
  "weeklyTips": ["string", "string", "string"],
  "foodsToAvoid": ["string", "string"],
  "groceryList": ["string", "string", "string"]
}`;

  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: 'You are a nutritionist expert. Always respond with valid JSON only. No markdown, no backticks.' },
      { role: 'user', content: prompt }
    ],
    max_tokens: 3000,
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

  const saved = await db.collection('nutrition').add({
    uid, planName: plan.planName, plan, macros,
    createdAt: new Date().toISOString(), mealsLogged: []
  });

  await db.collection('users').doc(uid).set(
    { points: (user.points || 0) + 10 },
    { merge: true }
  );

  return { nutritionId: saved.id, macros, plan, pointsEarned: 10 };
};

// ─────────────────────────────────────────
// FOOD SCANNER using Groq Vision
// ─────────────────────────────────────────
const scanFood = async (uid, imageBuffer, mimeType) => {
  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.exists ? userDoc.data() : {};

  // Convert image to base64
  const base64Image = imageBuffer.toString('base64');
  const imageUrl = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;

  const prompt = `
You are an expert nutritionist AI. Analyze this food image and return nutrition info as valid JSON only.
No extra text, no markdown, no backticks — pure JSON only.

User context:
- Fitness Goal: ${user.fitnessGoal || 'general fitness'}
- Daily Calorie Target: ${user.dailyCalorieTarget || 2000} kcal

Identify all food items visible. Estimate realistic portion sizes.
Include Sri Lankan food recognition (rice, curry, dhal, sambol, hoppers etc).

Return ONLY this JSON:
{
  "detected": true,
  "mealName": "string",
  "confidence": "high | medium | low",
  "items": [
    {
      "name": "string",
      "portion": "string",
      "calories": number,
      "protein": number,
      "carbs": number,
      "fats": number,
      "fiber": number
    }
  ],
  "totalNutrition": {
    "calories": number,
    "protein": number,
    "carbs": number,
    "fats": number,
    "fiber": number
  },
  "healthScore": number,
  "feedback": "string",
  "suggestion": "string",
  "isGoodForGoal": true
}`;

  // Groq Vision model
  const response = await groq.chat.completions.create({
    model: 'meta-llama/llama-4-scout-17b-16e-instruct', // supports vision
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          {
            type: 'image_url',
            image_url: { url: imageUrl }
          }
        ]
      }
    ],
    max_tokens: 1000,
    temperature: 0.3
  });

  let responseText = response.choices[0].message.content.trim();
  responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

  let scanResult;
  try {
    scanResult = JSON.parse(responseText);
  } catch (err) {
    throw new Error('Could not analyze food image. Please try a clearer photo.');
  }

  const saved = await db.collection('foodScans').add({
    uid, ...scanResult,
    scannedAt: new Date().toISOString()
  });

  await db.collection('users').doc(uid).set(
    { points: (user.points || 0) + 5 },
    { merge: true }
  );

  return { scanId: saved.id, ...scanResult, pointsEarned: 5 };
};

const logMeal = async (uid, nutritionId, mealType, actualCalories) => {
  const nutritionRef = db.collection('nutrition').doc(nutritionId);
  const doc = await nutritionRef.get();
  if (!doc.exists) throw new Error('Nutrition plan not found');
  if (doc.data().uid !== uid) throw new Error('Unauthorized');

  const logEntry = { mealType, actualCalories, loggedAt: new Date().toISOString() };
  await nutritionRef.update({
    mealsLogged: [...(doc.data().mealsLogged || []), logEntry]
  });

  const allLogs = [...(doc.data().mealsLogged || []), logEntry];
  const totalLogged = allLogs.reduce((sum, m) => sum + (m.actualCalories || 0), 0);
  const target = doc.data().plan.dailyCalories;

  return {
    success: true,
    totalCaloriesLogged: totalLogged,
    targetCalories: target,
    remaining: target - totalLogged
  };
};

const getNutritionHistory = async (uid) => {
  const snap = await db.collection('nutrition').where('uid', '==', uid).get();
  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 10);
};

const getLatestPlan = async (uid) => {
  const snap = await db.collection('nutrition').where('uid', '==', uid).get();
  if (snap.empty) return null;
  const sorted = snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  return sorted[0];
};

const getFoodScanHistory = async (uid) => {
  const snap = await db.collection('foodScans').where('uid', '==', uid).get();
  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.scannedAt) - new Date(a.scannedAt))
    .slice(0, 20);
};

module.exports = {
  generateMealPlan, logMeal,
  getNutritionHistory, getLatestPlan,
  scanFood, getFoodScanHistory
};