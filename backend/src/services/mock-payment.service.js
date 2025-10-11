class MockPaymentService {
  static async createPaymentIntent(amount, currency = 'LKR') {
    const timestamp = Date.now();
    return {
      id: `pi_mock_${timestamp}`,
      amount: amount,
      currency: currency,
      status: 'requires_payment_method',
      client_secret: `pi_mock_${timestamp}_secret`,
      created: Math.floor(timestamp / 1000)
    };
  }

  static async confirmPayment(paymentIntentId, cardNumber = '4242424242424242') {
    const timestamp = Date.now();
    const last4 = cardNumber.slice(-4);
    
    // Simulate different scenarios based on card number
    if (cardNumber === '4000000000000002') {
      return {
        id: paymentIntentId,
        status: 'requires_payment_method',
        last_payment_error: {
          message: 'Your card was declined.',
          type: 'card_error',
          code: 'card_declined'
        }
      };
    }
    
    if (cardNumber === '4000000000009995') {
      return {
        id: paymentIntentId,
        status: 'requires_payment_method',
        last_payment_error: {
          message: 'Your card has insufficient funds.',
          type: 'card_error',
          code: 'insufficient_funds'
        }
      };
    }
    
    if (cardNumber === '4000000000000069') {
      return {
        id: paymentIntentId,
        status: 'requires_payment_method',
        last_payment_error: {
          message: 'Your card has expired.',
          type: 'card_error',
          code: 'expired_card'
        }
      };
    }
    
    // Default success scenario
    return {
      id: paymentIntentId,
      status: 'succeeded',
      amount: null,
      currency: 'LKR',
      payment_method: {
        id: `pm_mock_${timestamp}`,
        type: 'card',
        card: {
          last4: last4,
          brand: 'visa'
        }
      },
      created: Math.floor(timestamp / 1000)
    };
  }

  static async refundPayment(paymentIntentId, amount = null) {
    const timestamp = Date.now();
    return {
      id: `re_mock_${timestamp}`,
      amount: amount,
      status: 'succeeded',
      payment_intent: paymentIntentId,
      created: Math.floor(timestamp / 1000)
    };
  }

  static async getPaymentStatus(paymentIntentId) {
    // For mock, assume all existing payment intents are successful
    const timestamp = Date.now();
    return {
      id: paymentIntentId,
      status: 'succeeded',
      created: Math.floor(timestamp / 1000)
    };
  }

  static generateTransactionId() {
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substring(2, 10).toUpperCase();
    return `TXN_${timestamp}_${randomStr}`;
  }
}

module.exports = MockPaymentService;

