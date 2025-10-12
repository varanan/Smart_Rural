const PricingService = require('../services/pricing.service');
const logger = require('../utils/logger');

// Get price estimation for a route
const getPriceEstimation = async (req, res, next) => {
  try {
    const { from, to, busType, journeyDate, seatCount = 1 } = req.query;

    // Validate required parameters
    if (!from || !to || !busType || !journeyDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameters: from, to, busType, journeyDate'
      });
    }

    // Validate bus type
    const validBusTypes = ['Normal', 'Express', 'Luxury', 'Semi-Luxury', 'Intercity'];
    if (!validBusTypes.includes(busType)) {
      return res.status(400).json({
        success: false,
        message: `Invalid bus type. Must be one of: ${validBusTypes.join(', ')}`
      });
    }

    // Parse journey date
    const journey = new Date(journeyDate);
    if (isNaN(journey.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid journey date format'
      });
    }

    const pricing = await PricingService.getPriceEstimation({
      from,
      to,
      busType,
      journeyDate: journey,
      seatCount: parseInt(seatCount)
    });

    logger.info('Price estimation requested', {
      from,
      to,
      busType,
      seatCount: parseInt(seatCount),
      totalPrice: pricing.totalPrice
    });

    res.json({
      success: true,
      message: 'Price estimation retrieved successfully',
      data: pricing
    });
  } catch (error) {
    logger.error('Error getting price estimation', { error: error.message });
    next(error);
  }
};

// Get all available routes
const getRoutes = async (req, res, next) => {
  try {
    const { from, to } = req.query;
    const filters = {};

    if (from) filters.from = from;
    if (to) filters.to = to;

    const routes = await PricingService.getRoutes(filters);

    logger.info('Routes requested', {
      filterFrom: from,
      filterTo: to,
      routeCount: routes.length
    });

    res.json({
      success: true,
      message: 'Routes retrieved successfully',
      data: routes,
      count: routes.length
    });
  } catch (error) {
    logger.error('Error getting routes', { error: error.message });
    next(error);
  }
};

// Get route details by ID
const getRouteById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const Route = require('../models/route.model');

    const route = await Route.findById(id).populate('createdBy', 'fullName email');

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    }

    logger.info('Route details requested', { routeId: id });

    res.json({
      success: true,
      message: 'Route details retrieved successfully',
      data: route
    });
  } catch (error) {
    logger.error('Error getting route details', { error: error.message });
    next(error);
  }
};

// Create new route (Admin only)
const createRoute = async (req, res, next) => {
  try {
    const routeData = {
      ...req.body,
      createdBy: req.user._id
    };

    const route = await PricingService.createRoute(routeData);

    logger.info('Route created', {
      routeCode: route.routeCode,
      createdBy: req.user._id
    });

    res.status(201).json({
      success: true,
      message: 'Route created successfully',
      data: route
    });
  } catch (error) {
    logger.error('Error creating route', { error: error.message });
    next(error);
  }
};

// Update route pricing (Admin only)
const updateRoutePricing = async (req, res, next) => {
  try {
    const { id } = req.params;
    const pricingData = req.body;

    const route = await PricingService.updateRoutePricing(id, pricingData);

    logger.info('Route pricing updated', {
      routeId: id,
      updatedBy: req.user._id
    });

    res.json({
      success: true,
      message: 'Route pricing updated successfully',
      data: route
    });
  } catch (error) {
    logger.error('Error updating route pricing', { error: error.message });
    next(error);
  }
};

// Get pricing breakdown for multiple routes
const getBulkPriceEstimation = async (req, res, next) => {
  try {
    const { routes } = req.body;

    if (!Array.isArray(routes) || routes.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Routes array is required'
      });
    }

    const results = [];
    
    for (const routeRequest of routes) {
      try {
        const { from, to, busType, journeyDate, seatCount = 1 } = routeRequest;
        
        if (!from || !to || !busType || !journeyDate) {
          results.push({
            from,
            to,
            busType,
            error: 'Missing required parameters'
          });
          continue;
        }

        const journey = new Date(journeyDate);
        if (isNaN(journey.getTime())) {
          results.push({
            from,
            to,
            busType,
            error: 'Invalid journey date format'
          });
          continue;
        }

        const pricing = await PricingService.getPriceEstimation({
          from,
          to,
          busType,
          journeyDate: journey,
          seatCount: parseInt(seatCount)
        });

        results.push({
          from,
          to,
          busType,
          seatCount: parseInt(seatCount),
          pricing
        });
      } catch (error) {
        results.push({
          from: routeRequest.from,
          to: routeRequest.to,
          busType: routeRequest.busType,
          error: error.message
        });
      }
    }

    logger.info('Bulk price estimation requested', {
      requestCount: routes.length,
      successCount: results.filter(r => !r.error).length
    });

    res.json({
      success: true,
      message: 'Bulk price estimation completed',
      data: results
    });
  } catch (error) {
    logger.error('Error getting bulk price estimation', { error: error.message });
    next(error);
  }
};

module.exports = {
  getPriceEstimation,
  getRoutes,
  getRouteById,
  createRoute,
  updateRoutePricing,
  getBulkPriceEstimation
};
