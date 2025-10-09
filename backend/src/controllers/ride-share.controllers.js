const { 
  rideShareSchema,
  rideRequestSchema,
  rideRequestResponseSchema
} = require('./validators/ride-share.validators');
const rideShareService = require('../services/ride-share.service');
const logger = require('../utils/logger');

const createRideShare = async (req, res, next) => {
  try {
    const { error, value } = rideShareSchema.validate(req.body);
    if (error) {
      error.status = 400;
      throw error;
    }

    const ride = await rideShareService.createRideShare(req.user.id, value);
    res.status(201).json({
      success: true,
      message: 'Ride share created successfully',
      data: ride
    });
  } catch (error) {
    next(error);
  }
};

const getRideShares = async (req, res, next) => {
  try {
    const rides = await rideShareService.getRideShares(req.query);
    res.json({
      success: true,
      message: 'Ride shares retrieved successfully',
      data: rides
    });
  } catch (error) {
    next(error);
  }
};

const getConnectorRides = async (req, res, next) => {
  try {
    const rides = await rideShareService.getConnectorRides(req.user.id);
    res.json({
      success: true,
      message: 'Connector rides retrieved successfully',
      data: rides
    });
  } catch (error) {
    next(error);
  }
};

const updateRideStatus = async (req, res, next) => {
  try {
    const ride = await rideShareService.updateRideStatus(req.params.id, req.body.isActive);
    if (!ride) {
      const error = new Error('Ride not found');
      error.status = 404;
      throw error;
    }

    res.json({
      success: true,
      message: 'Ride status updated successfully',
      data: ride
    });
  } catch (error) {
    next(error);
  }
};

const requestRide = async (req, res, next) => {
  try {
    const { error, value } = rideRequestSchema.validate(req.body);
    if (error) {
      error.status = 400;
      throw error;
    }

    const ride = await rideShareService.requestRide(value.rideId, req.user.id);
    res.json({
      success: true,
      message: 'Ride request sent successfully',
      data: ride
    });
  } catch (error) {
    next(error);
  }
};

const respondToRequest = async (req, res, next) => {
  try {
    const { error, value } = rideRequestResponseSchema.validate(req.body);
    if (error) {
      error.status = 400;
      throw error;
    }

    const ride = await rideShareService.respondToRequest(
      req.params.id,
      value.requestId,
      value.status
    );

    res.json({
      success: true,
      message: `Ride request ${value.status} successfully`,
      data: ride
    });
  } catch (error) {
    next(error);
  }
};

const getPassengerRides = async (req, res, next) => {
  try {
    const rides = await rideShareService.getPassengerRides(req.user.id);
    res.json({
      success: true,
      message: 'Passenger rides retrieved successfully',
      data: rides
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRideShare,
  getRideShares,
  getConnectorRides,
  updateRideStatus,
  requestRide,
  respondToRequest,
  getPassengerRides
};