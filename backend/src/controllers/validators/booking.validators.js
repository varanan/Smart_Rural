const Joi = require('joi');

const bookingSchema = Joi.object({
  timetableId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid timetable ID format',
      'string.empty': 'Timetable ID is required'
    }),
  
  seatNumbers: Joi.array()
    .items(Joi.string().pattern(/^[A-D][1-9]$|^[A-D]10$/))
    .min(1)
    .max(10)
    .required()
    .messages({
      'array.base': 'Seat numbers must be an array',
      'array.min': 'At least one seat must be selected',
      'array.max': 'Maximum 10 seats can be booked at once',
      'string.pattern.base': 'Invalid seat number format. Must be A1-D10'
    }),
  
  journeyDate: Joi.date()
    .required()
    .messages({
      'date.base': 'Journey date must be a valid date',
      'any.required': 'Journey date is required'
    }),
  
  totalAmount: Joi.number()
    .min(0)
    .required()
    .messages({
      'number.base': 'Total amount must be a number',
      'number.min': 'Total amount cannot be negative',
      'any.required': 'Total amount is required'
    })
});

const paymentSchema = Joi.object({
  paymentMethod: Joi.string()
    .valid('card', 'mobile', 'bank_transfer', 'cash')
    .default('card')
    .messages({
      'any.only': 'Payment method must be one of: card, mobile, bank_transfer, cash'
    }),
  
  cardNumber: Joi.string()
    .pattern(/^\d{16}$/)
    .when('paymentMethod', {
      is: 'card',
      then: Joi.required(),
      otherwise: Joi.optional()
    })
    .messages({
      'string.pattern.base': 'Card number must be 16 digits',
      'any.required': 'Card number is required for card payments'
    })
});

const seatAvailabilitySchema = Joi.object({
  timetableId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid timetable ID format',
      'string.empty': 'Timetable ID is required'
    }),
  
  journeyDate: Joi.date()
    .required()
    .messages({
      'date.base': 'Journey date must be a valid date',
      'any.required': 'Journey date is required'
    })
});

const validate = (schema) => {
  return (req, res, next) => {
    const dataToValidate = ['GET', 'DELETE'].includes(req.method) ? req.query : req.body;
    
    const { error, value } = schema.validate(dataToValidate, {
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

    if (['GET', 'DELETE'].includes(req.method)) {
      req.query = value;
    } else {
      req.body = value;
    }
    
    next();
  };
};

module.exports = {
  bookingSchema,
  paymentSchema,
  seatAvailabilitySchema,
  validate
};

