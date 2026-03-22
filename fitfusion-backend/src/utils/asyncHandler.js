// src/utils/asyncHandler.js
// Wrapper to catch async errors and pass to error middleware
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = asyncHandler;
