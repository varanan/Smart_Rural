# Smart Rural - Booking & Payment System Plan

## Overview
This document outlines the implementation plan for the booking and payment functionality in the Smart Rural bus transportation system.

## Core Features

### 1. Booking System
- **Seat Selection**: Interactive seat map with available/reserved seats
- **Passenger Details**: Collect passenger information (name, phone, email)
- **Booking Confirmation**: Generate booking reference numbers
- **Booking Management**: View, modify, and cancel bookings
- **Real-time Availability**: Check seat availability before booking

### 2. Payment Integration
- **Multiple Payment Methods**: 
  - Credit/Debit Cards (Stripe)
  - Mobile Payments (PayPal, Apple Pay, Google Pay)
  - Bank Transfers
  - Cash on Board (for rural areas)
- **Payment Security**: PCI DSS compliance, encrypted transactions
- **Payment Status Tracking**: Pending, completed, failed, refunded
- **Receipt Generation**: Digital receipts and booking confirmations

## Technical Architecture

### Backend Components

#### 1. Database Models
```
Booking Schema:
- bookingId (ObjectId)
- passengerId (ObjectId, ref: Passenger)
- timetableId (ObjectId, ref: BusTimeTable)
- seatNumbers (Array)
- bookingStatus (enum: pending, confirmed, cancelled)
- totalAmount (Number)
- bookingDate (Date)
- journeyDate (Date)
- passengerDetails (Object)
- paymentStatus (enum: pending, paid, failed, refunded)
- paymentId (String)
- createdAt, updatedAt

Payment Schema:
- paymentId (ObjectId)
- bookingId (ObjectId, ref: Booking)
- amount (Number)
- currency (String, default: LKR)
- paymentMethod (enum: card, mobile, bank_transfer, cash)
- paymentStatus (enum: pending, completed, failed, refunded)
- transactionId (String)
- gatewayResponse (Object)
- processedAt (Date)
```

#### 2. API Endpoints
```
POST /api/bookings - Create new booking
GET /api/bookings - Get user bookings (authenticated)
GET /api/bookings/:id - Get specific booking
PUT /api/bookings/:id - Update booking
DELETE /api/bookings/:id - Cancel booking
GET /api/bookings/:id/seats - Get seat availability

POST /api/payments - Process payment
GET /api/payments/:id - Get payment status
POST /api/payments/:id/refund - Process refund
GET /api/payments/webhook/stripe - Stripe webhook handler
```

#### 3. Services & Controllers
- `BookingController`: Handle booking CRUD operations
- `PaymentController`: Process payments and refunds
- `BookingService`: Business logic for bookings
- `PaymentService`: Payment processing logic
- `StripeService`: Stripe integration
- `EmailService`: Send booking confirmations

### Frontend Components

#### 1. Booking Flow Screens
- `SeatSelectionScreen`: Interactive seat map
- `PassengerDetailsScreen`: Collect passenger info
- `PaymentScreen`: Payment method selection and processing
- `BookingConfirmationScreen`: Show booking details and receipt
- `MyBookingsScreen`: View booking history

#### 2. UI Components
- `SeatMapWidget`: Visual seat selection
- `PaymentMethodCard`: Payment option display
- `BookingCard`: Booking summary display
- `PaymentForm`: Secure payment form
- `ReceiptWidget`: Booking receipt display

#### 3. State Management
- `BookingBloc`: Manage booking flow state
- `PaymentBloc`: Handle payment processing
- `BookingRepository`: API communication layer

## Implementation Phases

### Phase 1: Core Booking System (Week 1-2)
1. **Backend Setup**
   - Create booking and payment models
   - Implement basic booking CRUD APIs
   - Add seat management logic
   - Create booking controllers and services

2. **Frontend Foundation**
   - Create booking flow screens
   - Implement seat selection UI
   - Add booking state management
   - Create basic booking forms

### Phase 2: Payment Integration (Week 3)
1. **Payment Gateway Setup**
   - Integrate Stripe payment processing
   - Implement payment controllers
   - Add webhook handling for payment confirmations
   - Create payment status tracking

2. **Frontend Payment UI**
   - Create payment method selection
   - Implement secure payment forms
   - Add payment status indicators
   - Create receipt generation

### Phase 3: Advanced Features (Week 4)
1. **Booking Management**
   - Add booking modification capabilities
   - Implement booking cancellation
   - Create booking history and search
   - Add email notifications

2. **Admin Features**
   - Booking management dashboard
   - Payment monitoring and reporting
   - Refund processing tools
   - Analytics and insights

## Security Considerations

### Data Protection
- Encrypt sensitive passenger data
- Secure payment information handling
- Implement proper authentication and authorization
- Add rate limiting for API endpoints

### Payment Security
- PCI DSS compliance for card payments
- Tokenization for sensitive payment data
- Fraud detection and prevention
- Secure webhook validation

## Testing Strategy

### Backend Testing
- Unit tests for all services and controllers
- Integration tests for API endpoints
- Payment gateway testing (sandbox mode)
- Database transaction testing

### Frontend Testing
- Widget tests for UI components
- Integration tests for booking flow
- Payment flow testing
- User experience testing

## Deployment Considerations

### Environment Setup
- Development: Local with test payment gateways
- Staging: Cloud deployment with sandbox payments
- Production: Secure cloud deployment with live payments

### Monitoring
- Payment transaction monitoring
- Booking system performance tracking
- Error logging and alerting
- User behavior analytics

## Dependencies

### Backend Dependencies
```json
{
  "stripe": "^14.0.0",
  "nodemailer": "^6.9.0",
  "qrcode": "^1.5.3",
  "moment": "^2.29.4"
}
```

### Frontend Dependencies
```yaml
dependencies:
  flutter_stripe: ^9.0.0
  qr_flutter: ^4.1.0
  pdf: ^3.10.0
  email_validator: ^2.1.17
```

## Stripe Mocking Strategy

### Development Approach
For development and testing, we'll implement a comprehensive Stripe mocking system that allows us to:
- Test payment flows without real transactions
- Simulate different payment scenarios (success, failure, refunds)
- Develop offline without internet dependency
- Avoid Stripe API costs during development

### Mock Implementation Options

#### Option 1: Custom Mock Service (Recommended)
Create a mock payment service that mimics Stripe's behavior:

```javascript
// backend/src/services/mock-payment.service.js
class MockPaymentService {
  static async createPaymentIntent(amount, currency = 'lkr') {
    return {
      id: `pi_mock_${Date.now()}`,
      amount: amount,
      currency: currency,
      status: 'requires_payment_method',
      client_secret: `pi_mock_${Date.now()}_secret`,
      created: Math.floor(Date.now() / 1000)
    };
  }

  static async confirmPayment(paymentIntentId) {
    // Simulate different scenarios based on amount
    const scenarios = {
      success: () => ({ status: 'succeeded', id: paymentIntentId }),
      failure: () => ({ status: 'requires_payment_method', last_payment_error: { message: 'Your card was declined.' } }),
      processing: () => ({ status: 'processing', id: paymentIntentId })
    };
    
    // Use amount to determine scenario (e.g., amounts ending in 00 = success)
    const amount = parseInt(paymentIntentId.split('_')[2]);
    const scenario = amount % 100 === 0 ? 'success' : amount % 10 === 0 ? 'failure' : 'processing';
    
    return scenarios[scenario]();
  }

  static async refundPayment(paymentIntentId, amount = null) {
    return {
      id: `re_mock_${Date.now()}`,
      amount: amount,
      status: 'succeeded',
      payment_intent: paymentIntentId,
      created: Math.floor(Date.now() / 1000)
    };
  }
}
```

#### Option 2: Simple Mock-Only Service
Since this is a development-only project, we'll use a simple mock service:

```javascript
// backend/src/services/payment.service.js
class PaymentService {
  static async createPaymentIntent(amount, currency = 'lkr') {
    // Always use mock since this is development-only
    return MockPaymentService.createPaymentIntent(amount, currency);
  }

  static async confirmPayment(paymentIntentId) {
    return MockPaymentService.confirmPayment(paymentIntentId);
  }

  static async refundPayment(paymentIntentId, amount = null) {
    return MockPaymentService.refundPayment(paymentIntentId, amount);
  }
}
```

#### Option 3: Stripe Test Mode with Mock Cards
Use Stripe's test mode with predefined test card numbers:

```javascript
// Test card numbers for different scenarios
const TEST_CARDS = {
  SUCCESS: '4242424242424242',
  DECLINED: '4000000000000002',
  INSUFFICIENT_FUNDS: '4000000000009995',
  EXPIRED_CARD: '4000000000000069',
  PROCESSING_ERROR: '4000000000000119'
};
```

### Frontend Mock Implementation

#### Mock Payment Widget
```dart
// frontend/lib/widgets/mock_payment_widget.dart
class MockPaymentWidget extends StatefulWidget {
  final double amount;
  final Function(String) onPaymentSuccess;
  final Function(String) onPaymentFailure;

  const MockPaymentWidget({
    Key? key,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
  }) : super(key: key);

  @override
  _MockPaymentWidgetState createState() => _MockPaymentWidgetState();
}

class _MockPaymentWidgetState extends State<MockPaymentWidget> {
  final TextEditingController _cardController = TextEditingController();
  bool _isProcessing = false;

  void _processMockPayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));
    
    String cardNumber = _cardController.text.replaceAll(' ', '');
    
    // Mock different scenarios based on card number
    if (cardNumber == '4242424242424242') {
      widget.onPaymentSuccess('pi_mock_success_${DateTime.now().millisecondsSinceEpoch}');
    } else if (cardNumber == '4000000000000002') {
      widget.onPaymentFailure('Your card was declined.');
    } else {
      widget.onPaymentSuccess('pi_mock_success_${DateTime.now().millisecondsSinceEpoch}');
    }
    
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Mock Payment (Development Mode)', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            SizedBox(height: 16),
            TextFormField(
              controller: _cardController,
              decoration: InputDecoration(
                labelText: 'Test Card Number',
                hintText: '4242424242424242 (Success)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text('Test Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('4242424242424242 - Success'),
            Text('4000000000000002 - Declined'),
            Text('4000000000009995 - Insufficient Funds'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processMockPayment,
              child: _isProcessing 
                ? CircularProgressIndicator()
                : Text('Process Mock Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Configuration

#### Backend Configuration
```bash
# .env (development only)
NODE_ENV=development
# No Stripe keys needed - using mocks only
```

#### Frontend Configuration
```dart
// frontend/lib/core/config.dart
class AppConfig {
  // Always use mock payments for this development project
  static const bool USE_MOCK_PAYMENTS = true;
  static const String MOCK_PAYMENT_MODE = 'mock_only';
}
```

### Testing Scenarios

#### Payment Test Cases
```javascript
// backend/tests/payment.test.js
describe('Mock Payment Service', () => {
  test('should create payment intent successfully', async () => {
    const result = await MockPaymentService.createPaymentIntent(1000);
    expect(result.status).toBe('requires_payment_method');
    expect(result.amount).toBe(1000);
  });

  test('should handle successful payment', async () => {
    const paymentIntent = await MockPaymentService.createPaymentIntent(1000);
    const result = await MockPaymentService.confirmPayment(paymentIntent.id);
    expect(result.status).toBe('succeeded');
  });

  test('should handle failed payment', async () => {
    const paymentIntent = await MockPaymentService.createPaymentIntent(1001);
    const result = await MockPaymentService.confirmPayment(paymentIntent.id);
    expect(result.status).toBe('requires_payment_method');
  });
});
```

### Benefits of Mocking

1. **Development Speed**: No need to wait for real API calls
2. **Cost Effective**: No Stripe transaction fees during development
3. **Offline Development**: Works without internet connection
4. **Predictable Testing**: Consistent test scenarios
5. **Easy Debugging**: Clear mock responses for troubleshooting

### Development Strategy

1. **Phase 1**: Develop with mocks only (current)
2. **Phase 2**: Enhance mock scenarios for better testing
3. **Phase 3**: Add more payment methods (cash, bank transfer)
4. **Phase 4**: Keep it simple - mock-only for demo purposes

### Mock Data Examples

#### Successful Payment Response
```json
{
  "id": "pi_mock_1704067200000",
  "amount": 1500,
  "currency": "lkr",
  "status": "succeeded",
  "client_secret": "pi_mock_1704067200000_secret",
  "created": 1704067200,
  "payment_method": "pm_mock_card",
  "receipt_email": "customer@example.com"
}
```

#### Failed Payment Response
```json
{
  "id": "pi_mock_1704067200001",
  "amount": 1500,
  "currency": "lkr",
  "status": "requires_payment_method",
  "last_payment_error": {
    "message": "Your card was declined.",
    "type": "card_error",
    "code": "card_declined"
  }
}
```

## Success Metrics

### Business Metrics
- Booking conversion rate
- Payment success rate
- Average booking value
- Customer satisfaction scores

### Technical Metrics
- API response times
- Payment processing time
- System uptime
- Error rates

## Future Enhancements

### Advanced Features
- Mobile app integration
- SMS notifications
- Loyalty program integration
- Dynamic pricing
- Multi-language support
- Accessibility improvements

### Scalability
- Microservices architecture
- Load balancing
- Database optimization
- Caching strategies
- CDN integration

---

## Getting Started

1. **Setup Development Environment**
   ```bash
   # Backend setup
   cd backend
   npm install
   
   # Frontend setup
   cd frontend
   flutter pub get
   ```

2. **Configure Payment Gateway**
   - Get Stripe API keys
   - Set up webhook endpoints
   - Configure test environment

3. **Database Migration**
   - Run booking and payment model migrations
   - Seed initial data for testing

4. **Start Development**
   - Begin with Phase 1 implementation
   - Follow test-driven development approach
   - Regular code reviews and testing

---

*This plan is a living document and will be updated as development progresses.*
