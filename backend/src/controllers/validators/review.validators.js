const Joi = require('joi');

const createReviewSchema = Joi.object({
  busId: Joi.string().required().messages({
    'string.empty': 'Bus ID is required',
    'any.required': 'Bus ID is required'
  }),
  rating: Joi.number().integer().min(1).max(5).required().messages({
    'number.base': 'Rating must be a number',
    'number.min': 'Rating must be at least 1',
    'number.max': 'Rating cannot exceed 5',
    'any.required': 'Rating is required'
  }),
  comment: Joi.string().min(10).max(500).required().messages({
    'string.empty': 'Comment is required',
    'string.min': 'Comment must be at least 10 characters',
    'string.max': 'Comment cannot exceed 500 characters',
    'any.required': 'Comment is required'
  })
});

const updateReviewSchema = Joi.object({
  rating: Joi.number().integer().min(1).max(5).messages({
    'number.base': 'Rating must be a number',
    'number.min': 'Rating must be at least 1',
    'number.max': 'Rating cannot exceed 5'
  }),
  comment: Joi.string().min(10).max(500).messages({
    'string.min': 'Comment must be at least 10 characters',
    'string.max': 'Comment cannot exceed 500 characters'
  })
}).min(1);

const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }
    next();
  };
};

module.exports = {
  createReviewSchema,
  updateReviewSchema,
  validate
};