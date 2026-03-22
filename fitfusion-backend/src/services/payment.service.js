// src/services/payment.service.js
const { db } = require('../config/firebase');

const PLANS = [
  {
    id: 'basic_monthly',
    name: 'Basic',
    price: 2500,
    currency: 'LKR',
    period: 'monthly',
    billingPeriod: 'monthly',
    features: [
      'Gym access 6am-10pm',
      'Basic equipment access',
      'Locker room access',
      '1 Group class per week',
    ],
    color: '#9E9E9E',
    popular: false,
    savings: null,
  },
  {
    id: 'premium_monthly',
    name: 'Premium',
    price: 4500,
    currency: 'LKR',
    period: 'monthly',
    billingPeriod: 'monthly',
    features: [
      '24/7 Gym access',
      'All equipment access',
      'Unlimited group classes',
      '1 PT session per month',
      'FitFusion app full access',
      'Nutrition consultation',
    ],
    color: '#E8845C',
    popular: true,
    savings: null,
  },
  {
    id: 'premium_yearly',
    name: 'Premium Annual',
    price: 45000,
    currency: 'LKR',
    period: 'yearly',
    billingPeriod: 'yearly',
    savings: 'Save LKR 9,000',
    features: [
      'Everything in Premium',
      '2 months FREE',
      '2 PT sessions per month',
      'Body composition analysis',
      'Priority class booking',
      'Guest passes (2/month)',
    ],
    color: '#D4673A',
    popular: false,
  },
  {
    id: 'student_monthly',
    name: 'Student',
    price: 1800,
    currency: 'LKR',
    period: 'monthly',
    billingPeriod: 'monthly',
    features: [
      'Gym access 6am-8pm',
      'Basic equipment',
      '2 Group classes per week',
      'Valid student ID required',
    ],
    color: '#4A90E2',
    popular: false,
    savings: null,
  },
];

const generateInvoiceNumber = () => {
  const date = new Date();
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.random().toString(36).substr(2, 4).toUpperCase();
  return `INV-${dateStr}-${random}`;
};

const calculateEndDate = (billingPeriod) => {
  const end = new Date();
  if (billingPeriod === 'monthly') {
    end.setMonth(end.getMonth() + 1);
  } else {
    end.setFullYear(end.getFullYear() + 1);
  }
  return end.toISOString();
};

const simulatePayment = async (cardLast4) => {
  await new Promise((resolve) => setTimeout(resolve, 2000));
  if (cardLast4 === '0000') throw new Error('Payment declined');
  return { success: true, transactionId: `TXN-${Date.now()}` };
};

const getPlans = async (uid) => {
  let currentSubscription = null;
  try {
    const subDoc = await db.collection('subscriptions').doc(uid).get();
    if (subDoc.exists) {
      currentSubscription = { id: subDoc.id, ...subDoc.data() };
      // Check expiry
      if (currentSubscription.endDate && new Date(currentSubscription.endDate) < new Date()) {
        if (currentSubscription.status === 'active') {
          await db.collection('subscriptions').doc(uid).update({ status: 'expired', updatedAt: new Date().toISOString() });
          currentSubscription.status = 'expired';
        }
      }
    }
  } catch (e) {
    // no subscription yet
  }
  return { plans: PLANS, currentSubscription };
};

const subscribe = async (uid, planId, cardDetails) => {
  const plan = PLANS.find((p) => p.id === planId);
  if (!plan) throw new Error('Invalid plan');

  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) throw new Error('User not found');
  const user = userDoc.data();

  const invoiceNumber = generateInvoiceNumber();
  const endDate = calculateEndDate(plan.billingPeriod);

  // Simulate payment - throws on failure
  await simulatePayment(cardDetails.last4);

  const now = new Date().toISOString();

  const payment = {
    uid,
    memberName: user.name || user.displayName || 'Member',
    memberEmail: user.email || '',
    planId: plan.id,
    planName: plan.name,
    amount: plan.price,
    currency: 'LKR',
    status: 'completed',
    paymentMethod: 'card',
    cardLast4: cardDetails.last4,
    cardBrand: cardDetails.brand || 'other',
    invoiceNumber,
    billingPeriod: plan.billingPeriod,
    startDate: now,
    endDate,
    createdAt: now,
    receiptUrl: '',
    notes: '',
  };

  const paymentRef = await db.collection('payments').add(payment);

  await db.collection('subscriptions').doc(uid).set({
    uid,
    planId: plan.id,
    planName: plan.name,
    status: 'active',
    amount: plan.price,
    billingPeriod: plan.billingPeriod,
    startDate: now,
    endDate,
    autoRenew: true,
    cardLast4: cardDetails.last4,
    cardBrand: cardDetails.brand || 'other',
    lastPaymentId: paymentRef.id,
    updatedAt: now,
    createdAt: now,
  });

  // Award 100 points
  const currentPoints = user.points || 0;
  await db.collection('users').doc(uid).set({ points: currentPoints + 100 }, { merge: true });

  return { paymentId: paymentRef.id, invoiceNumber, endDate, plan };
};

const getSubscription = async (uid) => {
  const subDoc = await db.collection('subscriptions').doc(uid).get();
  if (!subDoc.exists) return { subscription: null, daysRemaining: 0, isActive: false };

  const subscription = { id: subDoc.id, ...subDoc.data() };

  const now = new Date();
  const endDate = new Date(subscription.endDate);
  const daysRemaining = Math.max(0, Math.ceil((endDate - now) / (1000 * 60 * 60 * 24)));
  const isActive = subscription.status === 'active' && endDate > now;

  if (!isActive && subscription.status === 'active') {
    await db.collection('subscriptions').doc(uid).update({ status: 'expired', updatedAt: now.toISOString() });
    subscription.status = 'expired';
  }

  return { subscription, daysRemaining, isActive };
};

const getHistory = async (uid) => {
  // NOTE: Do NOT chain .orderBy() here — it requires a Firestore composite index
  // that may not exist. Sort in-memory instead.
  const snap = await db
    .collection('payments')
    .where('uid', '==', uid)
    .get();

  const payments = snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)); // newest first

  const totalPaid = payments
    .filter((p) => p.status === 'completed')
    .reduce((s, p) => s + (p.amount || 0), 0);

  return { payments, totalPaid, totalPayments: payments.length };
};

const getPayment = async (uid, paymentId) => {
  const doc = await db.collection('payments').doc(paymentId).get();
  if (!doc.exists) throw new Error('Payment not found');
  const payment = { id: doc.id, ...doc.data() };
  if (payment.uid !== uid) throw new Error('Unauthorized');
  return { payment };
};

const cancelSubscription = async (uid) => {
  const subDoc = await db.collection('subscriptions').doc(uid).get();
  if (!subDoc.exists) throw new Error('No active subscription');

  await db.collection('subscriptions').doc(uid).update({
    autoRenew: false,
    status: 'cancelled',
    updatedAt: new Date().toISOString(),
  });

  return { success: true, message: 'Subscription cancelled. You will retain access until the billing period ends.' };
};

const getSavedCards = async (uid) => {
  // No orderBy — avoids needing a composite index on the subcollection.
  const snap = await db.collection('savedCards').doc(uid).collection('cards').get();
  const cards = snap.docs
    .map((d) => ({ cardId: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)); // newest first
  return { cards };
};

const addCard = async (uid, cardData) => {
  const { last4, brand, expiryMonth, expiryYear, cardholderName, isDefault } = cardData;

  if (isDefault) {
    // Set all other cards to non-default
    const snap = await db.collection('savedCards').doc(uid).collection('cards').get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.update(d.ref, { isDefault: false }));
    await batch.commit();
  }

  const cardRef = db.collection('savedCards').doc(uid).collection('cards').doc();
  const card = {
    cardId: cardRef.id,
    last4,
    brand: brand || 'other',
    expiryMonth,
    expiryYear,
    cardholderName,
    isDefault: isDefault || false,
    createdAt: new Date().toISOString(),
  };
  await cardRef.set(card);

  return { success: true, card };
};

const deleteCard = async (uid, cardId) => {
  await db.collection('savedCards').doc(uid).collection('cards').doc(cardId).delete();
  return { success: true };
};

module.exports = {
  PLANS,
  getPlans,
  subscribe,
  getSubscription,
  getHistory,
  getPayment,
  cancelSubscription,
  getSavedCards,
  addCard,
  deleteCard,
};
