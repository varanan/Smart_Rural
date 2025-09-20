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
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid Sri Lankan phone number',
      'any.required': 'Phone number is required'
    }),
  
  licenseNumber: Joi.string()
    .pattern(/^[A-Z]\d{7}$/)
    .required()
    .messages({
      'string.pattern.base': 'License number must be in format A1234567',
      'any.required': 'License number is required'
    }),
  
  nicNumber: Joi.string()
    // Requirement: ^\d{9}[VXvx]$|^\d{12}$
    .pattern(/^\d{9}[VXvx]$|^\d{12}$/)
    .required()
    .messages({
      'string.pattern.base': 'NIC number must be 9 digits followed by V/v/X/x or 12 digits',
      'any.required': 'NIC number is required'
    }),
  
  busNumber: Joi.string()
    // Allow hyphen; two letters hyphen four digits (e.g., NA-1234)
    .pattern(/^[A-Z]{2}-\d{4}$/)
    .required()
    .messages({
      'string.pattern.base': 'Bus number must be in format AB-1234',
      'any.required': 'Bus number is required'
    })
});

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
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string()
    .required()
    .messages({
      'any.required': 'Refresh token is required'
    })
});

// Validation middleware
const validate = (schema) => {
  return (req, res, next) => {
    // collect all errors at once
    const { error } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
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