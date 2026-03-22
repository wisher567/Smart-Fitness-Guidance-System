// src/middleware/error.middleware.js

// Global error handler
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Default error
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal server error';

  // Firebase Auth errors
  if (err.code?.startsWith('auth/')) {
    statusCode = 401;
    message = 'Authentication failed';
  }

  // Firestore errors
  if (err.code?.includes('firestore')) {
    statusCode = 500;
    message = 'Database operation failed';
  }

  // Validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = err.message;
  }

  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// 404 handler
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.originalUrl} not found`
  });
};

module.exports = { errorHandler, notFoundHandler };
