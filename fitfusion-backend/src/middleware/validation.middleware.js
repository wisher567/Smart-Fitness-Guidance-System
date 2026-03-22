// src/middleware/validation.middleware.js
// Validation middleware placeholder
// Add request validation logic here as needed

const validateUserProfile = (req, res, next) => {
  const { name, age, weight, height, fitnessGoal, fitnessLevel } = req.body;
  
  if (!name || !age || !weight || !height || !fitnessGoal || !fitnessLevel) {
    return res.status(400).json({ 
      error: 'Missing required fields: name, age, weight, height, fitnessGoal, fitnessLevel' 
    });
  }
  
  if (age < 13 || age > 120) {
    return res.status(400).json({ error: 'Age must be between 13 and 120' });
  }
  
  if (weight < 20 || weight > 300) {
    return res.status(400).json({ error: 'Weight must be between 20 and 300 kg' });
  }
  
  if (height < 100 || height > 250) {
    return res.status(400).json({ error: 'Height must be between 100 and 250 cm' });
  }
  
  next();
};

module.exports = { validateUserProfile };
