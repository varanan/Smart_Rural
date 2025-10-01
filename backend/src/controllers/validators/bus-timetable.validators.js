const Joi = require('joi');

const busTimeTableSchema = Joi.object({
  from: Joi.string()
    .trim()
    .min(2)
    .max(50)
    .required()
    .messages({
      'string.empty': 'From location is required',
      'string.min': 'From location must be at least 2 characters',
      'string.max': 'From location must not exceed 50 characters'
    }),
  
  to: Joi.string()
    .trim()
    .min(2)
    .max(50)
    .required()
    .messages({
      'string.empty': 'To location is required',
      'string.min': 'To location must be at least 2 characters',
      'string.max': 'To location must not exceed 50 characters'
    }),
  
  startTime: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .required()
    .messages({
      'string.pattern.base': 'Start time must be in HH:MM format',
      'string.empty': 'Start time is required'
    }),
  
  endTime: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .required()
    .messages({
      'string.pattern.base': 'End time must be in HH:MM format',
      'string.empty': 'End time is required'
    }),
  
  busType: Joi.string()
    .valid('Normal', 'Express', 'Luxury', 'Semi-Luxury', 'Intercity')
    .default('Normal')
    .messages({
      'any.only': 'Bus type must be one of: Normal, Express, Luxury, Semi-Luxury, Intercity'
    })
});

const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      allowUnknown: false,
      stripUnknown: true
    });

    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }

    req.body = value;
    next();
  };
};

module.exports = {
  busTimeTableSchema,
  validate
};
