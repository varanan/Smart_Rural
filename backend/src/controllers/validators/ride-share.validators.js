const Joi = require('joi');

const rideShareSchema = Joi.object({
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
  
  vehicleType: Joi.string()
    .valid('Car', 'Motorbike')
    .required()
    .messages({
      'string.empty': 'Vehicle type is required',
      'any.only': 'Vehicle type must be either Car or Motorbike'
    }),

  seatCapacity: Joi.number()
    .integer()
    .min(1)
    .required()
    .messages({
      'number.base': 'Seat capacity must be a number',
      'number.integer': 'Seat capacity must be an integer',
      'number.min': 'Seat capacity must be at least 1',
      'any.required': 'Seat capacity is required'
    }),

  price: Joi.number()
    .min(0)
    .required()
    .messages({
      'number.base': 'Price must be a number',
      'number.min': 'Price cannot be negative',
      'any.required': 'Price is required'
    })
});

const rideRequestSchema = Joi.object({
  rideId: Joi.string()
    .required()
    .messages({
      'string.empty': 'Ride ID is required',
      'any.required': 'Ride ID is required'
    })
});

const rideRequestResponseSchema = Joi.object({
  requestId: Joi.string()
    .required()
    .messages({
      'string.empty': 'Request ID is required',
      'any.required': 'Request ID is required'
    }),
  
  status: Joi.string()
    .valid('accepted', 'rejected')
    .required()
    .messages({
      'string.empty': 'Status is required',
      'any.only': 'Status must be either accepted or rejected'
    })
});

module.exports = {
  rideShareSchema,
  rideRequestSchema,
  rideRequestResponseSchema
};