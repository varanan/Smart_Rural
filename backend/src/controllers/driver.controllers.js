const driverService = require('../services/driver.service');

const signupDriver = async (req, res, next) => {
  try {
    const result = await driverService.createDriver(req.body);
    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

const loginDriver = async (req, res, next) => {
  try {
    const result = await driverService.loginDriver(req.body);
    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  signupDriver,
  loginDriver
};