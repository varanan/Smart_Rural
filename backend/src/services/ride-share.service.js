const RideShare = require('../models/ride-share.model');
const logger = require('../utils/logger');

const createRideShare = async (connectorId, rideData) => {
  try {
    const ride = new RideShare({
      ...rideData,
      createdBy: connectorId
    });
    await ride.save();
    return ride;
  } catch (error) {
    logger.error('Error in createRideShare service:', error);
    throw error;
  }
};

const getRideShares = async (query = {}) => {
  try {
    const rides = await RideShare.find({ isActive: true, ...query })
      .populate('createdBy', 'fullName phone')
      .sort({ startTime: 1 });
    return rides;
  } catch (error) {
    logger.error('Error in getRideShares service:', error);
    throw error;
  }
};

const getConnectorRides = async (connectorId) => {
  try {
    const rides = await RideShare.find({ createdBy: connectorId })
      .populate('requests.passenger', 'fullName phone')
      .sort({ createdAt: -1 });
    return rides;
  } catch (error) {
    logger.error('Error in getConnectorRides service:', error);
    throw error;
  }
};

const updateRideStatus = async (rideId, isActive) => {
  try {
    const ride = await RideShare.findByIdAndUpdate(
      rideId,
      { isActive },
      { new: true }
    );
    return ride;
  } catch (error) {
    logger.error('Error in updateRideStatus service:', error);
    throw error;
  }
};

const requestRide = async (rideId, passengerId) => {
  try {
    const ride = await RideShare.findById(rideId);
    
    if (!ride) {
      const error = new Error('Ride not found');
      error.status = 404;
      throw error;
    }

    if (!ride.isActive) {
      const error = new Error('This ride is no longer active');
      error.status = 400;
      throw error;
    }

    // Check if passenger has already requested this ride
    const existingRequest = ride.requests.find(
      req => req.passenger.toString() === passengerId.toString()
    );

    if (existingRequest) {
      const error = new Error('You have already requested this ride');
      error.status = 400;
      throw error;
    }

    if (ride.availableSeats === 0) {
      const error = new Error('No seats available for this ride');
      error.status = 400;
      throw error;
    }

    ride.requests.push({ passenger: passengerId });
    await ride.save();
    
    return ride;
  } catch (error) {
    logger.error('Error in requestRide service:', error);
    throw error;
  }
};

const respondToRequest = async (rideId, requestId, status) => {
  try {
    const ride = await RideShare.findById(rideId);
    
    if (!ride) {
      const error = new Error('Ride not found');
      error.status = 404;
      throw error;
    }

    const request = ride.requests.id(requestId);
    
    if (!request) {
      const error = new Error('Request not found');
      error.status = 404;
      throw error;
    }

    if (request.status !== 'pending') {
      const error = new Error('This request has already been processed');
      error.status = 400;
      throw error;
    }

    request.status = status;

    // Update available seats if request is accepted
    if (status === 'accepted') {
      if (ride.availableSeats === 0) {
        const error = new Error('No seats available');
        error.status = 400;
        throw error;
      }
      ride.availableSeats -= 1;
    }

    await ride.save();
    return ride;
  } catch (error) {
    logger.error('Error in respondToRequest service:', error);
    throw error;
  }
};

const getPassengerRides = async (passengerId) => {
  try {
    const rides = await RideShare.find({
      'requests.passenger': passengerId
    })
      .populate('createdBy', 'fullName phone')
      .sort({ createdAt: -1 });
    return rides;
  } catch (error) {
    logger.error('Error in getPassengerRides service:', error);
    throw error;
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