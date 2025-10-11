const Route = require('../models/route.model');
const logger = require('../utils/logger');

class PricingService {
  // Default bus type multipliers (can be overridden by route-specific ones)
  static DEFAULT_BUS_TYPE_MULTIPLIERS = {
    'Normal': 1.0,
    'Express': 1.3,
    'Semi-Luxury': 1.5,
    'Luxury': 2.0,
    'Intercity': 1.2
  };

  // Peak hours (24-hour format)
  static PEAK_HOURS = {
    morning: { start: 6, end: 9 },
    evening: { start: 17, end: 20 }
  };

  // Weekend days (0 = Sunday, 6 = Saturday)
  static WEEKEND_DAYS = [0, 6];

  // Sri Lankan public holidays (you can expand this list)
  static HOLIDAYS = [
    '01-01', // New Year
    '02-04', // Independence Day
    '05-01', // May Day
    '12-25', // Christmas
    // Add more holidays as needed
  ];

  /**
   * Calculate price for a booking based on route, bus type, and other factors
   * @param {string} from - Origin location
   * @param {string} to - Destination location
   * @param {string} busType - Type of bus
   * @param {Date} journeyDate - Date of journey
   * @param {number} seatCount - Number of seats
   * @returns {Object} Pricing details
   */
  static async calculatePrice(from, to, busType, journeyDate, seatCount = 1) {
    try {
      logger.info('Calculating price', { from, to, busType, journeyDate, seatCount });

      // Find the route
      const route = await Route.findOne({
        from: from.toUpperCase(),
        to: to.toUpperCase(),
        isActive: true
      });

      if (!route) {
        throw new Error(`Route from ${from} to ${to} not found`);
      }

      // Calculate base price
      const basePrice = route.basePrice; // This uses the virtual field

      // Get bus type multiplier (route-specific or default)
      const busTypeMultiplier = route.busTypeMultipliers[busType] || 
                               this.DEFAULT_BUS_TYPE_MULTIPLIERS[busType] || 
                               1.0;

      // Calculate time-based multipliers
      const timeMultipliers = this.calculateTimeMultipliers(journeyDate);

      // Calculate final price per seat
      const pricePerSeat = Math.round(
        basePrice * 
        busTypeMultiplier * 
        timeMultipliers.peakHour * 
        timeMultipliers.weekend * 
        timeMultipliers.holiday
      );

      // Calculate total price
      const totalPrice = pricePerSeat * seatCount;

      const pricing = {
        route: {
          from: route.from,
          to: route.to,
          distance: route.distance,
          routeCode: route.routeCode
        },
        basePrice: basePrice,
        busType: busType,
        busTypeMultiplier: busTypeMultiplier,
        timeMultipliers: timeMultipliers,
        pricePerSeat: pricePerSeat,
        seatCount: seatCount,
        totalPrice: totalPrice,
        currency: 'LKR',
        breakdown: {
          basePrice: basePrice,
          busTypeAdjustment: basePrice * (busTypeMultiplier - 1),
          peakHourAdjustment: basePrice * busTypeMultiplier * (timeMultipliers.peakHour - 1),
          weekendAdjustment: basePrice * busTypeMultiplier * timeMultipliers.peakHour * (timeMultipliers.weekend - 1),
          holidayAdjustment: basePrice * busTypeMultiplier * timeMultipliers.peakHour * timeMultipliers.weekend * (timeMultipliers.holiday - 1)
        }
      };

      logger.info('Price calculated successfully', { 
        routeCode: route.routeCode, 
        totalPrice, 
        pricePerSeat 
      });

      return pricing;
    } catch (error) {
      logger.error('Error calculating price', { error: error.message });
      throw error;
    }
  }

  /**
   * Calculate time-based multipliers for pricing
   * @param {Date} journeyDate - Date and time of journey
   * @returns {Object} Time multipliers
   */
  static calculateTimeMultipliers(journeyDate) {
    const date = new Date(journeyDate);
    const hour = date.getHours();
    const dayOfWeek = date.getDay();
    const monthDay = `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

    // Check if it's a peak hour
    const isPeakHour = this.isPeakHour(hour);
    const peakHourMultiplier = isPeakHour ? 1.2 : 1.0;

    // Check if it's weekend
    const isWeekend = this.WEEKEND_DAYS.includes(dayOfWeek);
    const weekendMultiplier = isWeekend ? 1.1 : 1.0;

    // Check if it's a holiday
    const isHoliday = this.HOLIDAYS.includes(monthDay);
    const holidayMultiplier = isHoliday ? 1.3 : 1.0;

    return {
      peakHour: peakHourMultiplier,
      weekend: weekendMultiplier,
      holiday: holidayMultiplier,
      isPeakHour,
      isWeekend,
      isHoliday
    };
  }

  /**
   * Check if given hour is during peak hours
   * @param {number} hour - Hour in 24-hour format
   * @returns {boolean}
   */
  static isPeakHour(hour) {
    const morningPeak = hour >= this.PEAK_HOURS.morning.start && hour < this.PEAK_HOURS.morning.end;
    const eveningPeak = hour >= this.PEAK_HOURS.evening.start && hour < this.PEAK_HOURS.evening.end;
    return morningPeak || eveningPeak;
  }

  /**
   * Get all available routes
   * @param {Object} filters - Optional filters
   * @returns {Array} List of routes
   */
  static async getRoutes(filters = {}) {
    try {
      const query = { isActive: true };
      
      if (filters.from) {
        query.from = { $regex: filters.from, $options: 'i' };
      }
      
      if (filters.to) {
        query.to = { $regex: filters.to, $options: 'i' };
      }

      const routes = await Route.find(query)
        .populate('createdBy', 'fullName email')
        .sort({ from: 1, to: 1 });

      return routes;
    } catch (error) {
      logger.error('Error fetching routes', { error: error.message });
      throw error;
    }
  }

  /**
   * Create a new route
   * @param {Object} routeData - Route information
   * @returns {Object} Created route
   */
  static async createRoute(routeData) {
    try {
      const route = new Route(routeData);
      await route.save();
      
      logger.info('Route created successfully', { 
        routeCode: route.routeCode, 
        distance: route.distance 
      });
      
      return route;
    } catch (error) {
      logger.error('Error creating route', { error: error.message });
      throw error;
    }
  }

  /**
   * Update route pricing
   * @param {string} routeId - Route ID
   * @param {Object} pricingData - New pricing information
   * @returns {Object} Updated route
   */
  static async updateRoutePricing(routeId, pricingData) {
    try {
      const route = await Route.findByIdAndUpdate(
        routeId,
        { $set: pricingData },
        { new: true, runValidators: true }
      );

      if (!route) {
        throw new Error('Route not found');
      }

      logger.info('Route pricing updated', { 
        routeCode: route.routeCode, 
        newBasePrice: route.basePrice 
      });

      return route;
    } catch (error) {
      logger.error('Error updating route pricing', { error: error.message });
      throw error;
    }
  }

  /**
   * Get price estimation without creating a booking
   * @param {Object} params - Pricing parameters
   * @returns {Object} Price estimation
   */
  static async getPriceEstimation(params) {
    const { from, to, busType, journeyDate, seatCount } = params;
    
    return await this.calculatePrice(from, to, busType, journeyDate, seatCount);
  }
}

module.exports = PricingService;
