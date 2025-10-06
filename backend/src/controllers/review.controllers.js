const Review = require('../models/review.model');
const BusTimeTable = require('../models/bus-timetable.model');
const Passenger = require('../models/passenger.model');
const logger = require('../utils/logger');

// Create a new review
const createReview = async (req, res) => {
  try {
    const { busId, rating, comment } = req.body;
    const passengerId = req.user.id || req.user._id;

    // Check if bus exists
    const bus = await BusTimeTable.findById(busId);
    if (!bus) {
      return res.status(404).json({
        success: false,
        message: 'Bus not found'
      });
    }

    // Check if review already exists
    const existingReview = await Review.findOne({ busId, passengerId });
    if (existingReview) {
      return res.status(409).json({
        success: false,
        message: 'You have already reviewed this bus. Please update your existing review.'
      });
    }

    // Create review
    const review = await Review.create({
      busId,
      passengerId,
      rating,
      comment
    });

    // Populate passenger info
    await review.populate('passengerId', 'fullName email');
    await review.populate('busId', 'from to busType');

    logger.info('Review created', { reviewId: review._id, passengerId });

    res.status(201).json({
      success: true,
      message: 'Review created successfully',
      data: review
    });
  } catch (error) {
    logger.error('Create review failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to create review'
    });
  }
};

// Get all reviews for a specific bus
const getReviewsByBus = async (req, res) => {
  try {
    const { busId } = req.params;

    const reviews = await Review.find({ busId, isActive: true })
      .populate('passengerId', 'fullName')
      .populate('busId', 'from to busType')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: reviews,
      count: reviews.length
    });
  } catch (error) {
    logger.error('Get reviews by bus failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews'
    });
  }
};

// Get passenger's own reviews
const getMyReviews = async (req, res) => {
  try {
    const passengerId = req.user.id || req.user._id;

    const reviews = await Review.find({ passengerId, isActive: true })
      .populate('busId', 'from to busType startTime endTime')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: reviews,
      count: reviews.length
    });
  } catch (error) {
    logger.error('Get my reviews failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews'
    });
  }
};

// Update a review (passenger only)
const updateReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body;
    const passengerId = req.user.id || req.user._id;

    const review = await Review.findOne({ _id: id, passengerId });

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found or you do not have permission to update it'
      });
    }

    if (rating !== undefined) review.rating = rating;
    if (comment !== undefined) review.comment = comment;

    await review.save();
    await review.populate('passengerId', 'fullName email');
    await review.populate('busId', 'from to busType');

    logger.info('Review updated', { reviewId: review._id, passengerId });

    res.json({
      success: true,
      message: 'Review updated successfully',
      data: review
    });
  } catch (error) {
    logger.error('Update review failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to update review'
    });
  }
};

// Delete a review (passenger can delete their own, admin can delete any)
const deleteReview = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id || req.user._id;
    const userRole = req.user.role;

    let review;
    if (userRole === 'admin' || userRole === 'super_admin') {
      // Admin can delete any review
      review = await Review.findById(id);
    } else {
      // Passenger can only delete their own
      review = await Review.findOne({ _id: id, passengerId: userId });
    }

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found or you do not have permission to delete it'
      });
    }

    // Soft delete
    review.isActive = false;
    await review.save();

    logger.info('Review deleted', { reviewId: review._id, deletedBy: userId });

    res.json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    logger.error('Delete review failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to delete review'
    });
  }
};

// Get all reviews (for admin, driver, connector)
const getAllReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ isActive: true })
      .populate('passengerId', 'fullName email')
      .populate('busId', 'from to busType startTime endTime')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: reviews,
      count: reviews.length
    });
  } catch (error) {
    logger.error('Get all reviews failed', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews'
    });
  }
};

module.exports = {
  createReview,
  getReviewsByBus,
  getMyReviews,
  updateReview,
  deleteReview,
  getAllReviews
};