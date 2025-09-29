const Joi = require('joi');

const signupSchema = Joi.object({
  fullName: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Full name must be at least 2 characters',
      'string.max': 'Full name cannot exceed 100 characters',
      'any.required': 'Full name is required'
    }),
  
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Please enter a valid email address',
      'any.required': 'Email is required'
    }),
  
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[A-Za-z])(?=.*\d)/)
    .required()
    .messages({
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must contain at least one letter and one number',
      'any.required': 'Password is required'
    }),
  
  confirmPassword: Joi.string()
    .valid(Joi.ref('password'))
    .required()
    .messages({
      'any.only': 'Passwords do not match',
      'any.required': 'Please confirm your password'
    }),
  
  phone: Joi.string()
    .pattern(/^0\d{9}$/)
    .optional()
    .allow('')
    .messages({
      'string.pattern.base': 'Please enter a valid Sri Lankan phone number'
    })
}).unknown(false); // Reject any unknown fields

const loginSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Please enter a valid email address',
      'any.required': 'Email is required'
    }),
  
  password: Joi.string()
    .required()
    .messages({
      'any.required': 'Password is required'
    })
}).unknown(false); // Reject any unknown fields

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string()
    .required()
    .messages({
      'any.required': 'Refresh token is required'
    })
}).unknown(false); // Reject any unknown fields

// Validation middleware
const validate = (schema) => {
  return (req, res, next) => {
    // collect all errors at once
    const { error } = schema.validate(req.body, { 
      abortEarly: false, 
      stripUnknown: true,
      allowUnknown: false 
    });
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
  signupSchema,
  loginSchema,
  refreshTokenSchema,
  validate
};
