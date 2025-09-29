const connectorService = require('../services/connector.service');

const registerConnector = async (req, res, next) => {
  try {
    const result = await connectorService.registerConnector(req.body);
    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

const loginConnector = async (req, res, next) => {
  try {
    const result = await connectorService.loginConnector(req.body);
    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerConnector,
  loginConnector
};