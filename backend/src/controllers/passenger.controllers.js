const passengerService = require('../services/passenger.service');

const registerPassenger = async (req, res, next) => {
  try {
    // Debug: Log the request body to see what's being sent
    console.log('Passenger registration request body:', JSON.stringify(req.body, null, 2));
    
    const result = await passengerService.createPassenger(req.body);
    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Passenger registration error:', error.message);
    next(error);
  }
};

const loginPassenger = async (req, res, next) => {
  try {
    const result = await passengerService.loginPassenger(req.body);
    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerPassenger,
  loginPassenger
};
