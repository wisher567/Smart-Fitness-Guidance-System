const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth.middleware');
const { verifyTrainer } = require('../middleware/trainer.middleware');
const ctrl = require('../controllers/trainer.controller');

// All routes need token + trainer/admin role
const auth = [verifyToken, verifyTrainer];

router.get('/dashboard',              auth, ctrl.getDashboard);
router.get('/clients',                auth, ctrl.getMyClients);
router.get('/clients/:uid',           auth, ctrl.getClientDetail);
router.get('/clients/:uid/workouts',  auth, ctrl.getClientWorkouts);
router.get('/clients/:uid/nutrition', auth, ctrl.getClientNutrition);
router.get('/classes',                auth, ctrl.getMyClasses);
router.get('/plans',                  auth, ctrl.getMyPlans);
router.post('/plans',                 auth, ctrl.createPlan);
router.patch('/plans/:id',            auth, ctrl.updatePlan);
router.delete('/plans/:id',           auth, ctrl.deletePlan);
router.post('/plans/:id/assign',      auth, ctrl.assignPlanToClient);
router.get('/chat/clients',           auth, ctrl.getChatClients);
router.get('/chat/:uid',              auth, ctrl.getChatHistory);
router.post('/chat/:uid',             auth, ctrl.sendMessage);
router.get('/clients/:uid/notes',     auth, ctrl.getClientNotes);
router.post('/clients/:uid/notes',    auth, ctrl.addClientNote);
router.patch('/profile',              auth, ctrl.updateProfile);

module.exports = router;
