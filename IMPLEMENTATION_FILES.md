# Booking + Payment Implementation - Files Overview

## Summary
- **Backend**: 10 new files, 1 file to edit
- **Frontend**: 15 new files, 1 file to edit
- **Total**: 25 new files, 2 files to edit

---

## Backend Files

### 📁 New Files to Create (10 files)

#### 1. Models (2 files)
```
backend/src/models/booking.model.js
backend/src/models/payment.model.js
```

**Purpose**:
- `booking.model.js`: MongoDB schema for bookings (passenger, timetable, seats, status)
- `payment.model.js`: MongoDB schema for payments (amount, method, status, transaction)

#### 2. Controllers (2 files)
```
backend/src/controllers/booking.controllers.js
backend/src/controllers/payment.controllers.js
```

**Purpose**:
- `booking.controllers.js`: Handle booking CRUD operations (create, read, update, delete, cancel)
- `payment.controllers.js`: Handle payment processing and status checks

#### 3. Services (3 files)
```
backend/src/services/booking.service.js
backend/src/services/payment.service.js
backend/src/services/mock-payment.service.js
```

**Purpose**:
- `booking.service.js`: Business logic for bookings, seat management, availability
- `payment.service.js`: Payment processing orchestration
- `mock-payment.service.js`: Mock Stripe payment implementation

#### 4. Routes (1 file)
```
backend/src/routes/booking.routes.js
```

**Purpose**:
- Define API endpoints for bookings and payments
- Connect routes to controllers with authentication middleware

#### 5. Validators (1 file)
```
backend/src/controllers/validators/booking.validators.js
```

**Purpose**:
- Validation schemas for booking and payment requests

#### 6. Utilities (1 file)
```
backend/src/utils/booking-helpers.js
```

**Purpose**:
- Helper functions for seat calculations, pricing, booking reference generation

### ✏️ Files to Edit (1 file)

#### backend/src/app.js
**Changes**:
- Import booking routes
- Add route: `app.use('/api/bookings', bookingRoutes);`

**Location**: After line 14 and line 44

---

## Frontend Files

### 📁 New Files to Create (15 files)

#### 1. Models (2 files)
```
frontend/lib/models/booking.dart
frontend/lib/models/payment.dart
```

**Purpose**:
- `booking.dart`: Booking model with JSON serialization
- `payment.dart`: Payment model with JSON serialization

#### 2. Features - Booking Screens (6 files)
```
frontend/lib/features/booking/seat_selection_screen.dart
frontend/lib/features/booking/passenger_details_screen.dart
frontend/lib/features/booking/payment_screen.dart
frontend/lib/features/booking/booking_confirmation_screen.dart
frontend/lib/features/booking/my_bookings_screen.dart
frontend/lib/features/booking/booking_details_screen.dart
```

**Purpose**:
- `seat_selection_screen.dart`: Interactive seat map for selecting seats
- `passenger_details_screen.dart`: Form to collect passenger information
- `payment_screen.dart`: Payment method selection and mock payment processing
- `booking_confirmation_screen.dart`: Show booking confirmation with receipt
- `my_bookings_screen.dart`: List all user bookings with search/filter
- `booking_details_screen.dart`: Detailed view of a single booking

#### 3. Widgets (5 files)
```
frontend/lib/widgets/seat_map_widget.dart
frontend/lib/widgets/payment_method_card.dart
frontend/lib/widgets/booking_card.dart
frontend/lib/widgets/mock_payment_widget.dart
frontend/lib/widgets/booking_receipt_widget.dart
```

**Purpose**:
- `seat_map_widget.dart`: Visual seat selection grid (available/occupied/selected)
- `payment_method_card.dart`: Display payment method options
- `booking_card.dart`: Card widget for booking list items
- `mock_payment_widget.dart`: Mock payment form with test card numbers
- `booking_receipt_widget.dart`: Formatted booking receipt/ticket

#### 4. Services (1 file)
```
frontend/lib/services/booking_service.dart
```

**Purpose**:
- API calls for bookings (create, fetch, cancel)
- Handle booking state and caching

#### 5. State Management (optional, if using BLoC/Provider)
```
frontend/lib/blocs/booking_bloc.dart
```

**Purpose**:
- Manage booking flow state (seat selection, passenger details, payment)
- Handle booking operations and events

### ✏️ Files to Edit (1 file)

#### frontend/lib/services/api_service.dart
**Changes**:
- Add booking API methods:
  - `createBooking()`
  - `getBookings()`
  - `getBookingById()`
  - `cancelBooking()`
  - `processPayment()`
  - `getSeatAvailability()`

**Location**: Add methods after existing API methods (around line 390)

---

## Detailed File Structure

### Backend Structure
```
backend/src/
├── models/
│   ├── booking.model.js          [NEW] ✨
│   └── payment.model.js          [NEW] ✨
├── controllers/
│   ├── booking.controllers.js    [NEW] ✨
│   ├── payment.controllers.js    [NEW] ✨
│   └── validators/
│       └── booking.validators.js [NEW] ✨
├── services/
│   ├── booking.service.js        [NEW] ✨
│   ├── payment.service.js        [NEW] ✨
│   └── mock-payment.service.js   [NEW] ✨
├── routes/
│   └── booking.routes.js         [NEW] ✨
├── utils/
│   └── booking-helpers.js        [NEW] ✨
└── app.js                        [EDIT] ✏️
```

### Frontend Structure
```
frontend/lib/
├── models/
│   ├── booking.dart              [NEW] ✨
│   └── payment.dart              [NEW] ✨
├── features/
│   └── booking/
│       ├── seat_selection_screen.dart         [NEW] ✨
│       ├── passenger_details_screen.dart      [NEW] ✨
│       ├── payment_screen.dart                [NEW] ✨
│       ├── booking_confirmation_screen.dart   [NEW] ✨
│       ├── my_bookings_screen.dart            [NEW] ✨
│       └── booking_details_screen.dart        [NEW] ✨
├── widgets/
│   ├── seat_map_widget.dart      [NEW] ✨
│   ├── payment_method_card.dart  [NEW] ✨
│   ├── booking_card.dart         [NEW] ✨
│   ├── mock_payment_widget.dart  [NEW] ✨
│   └── booking_receipt_widget.dart [NEW] ✨
├── services/
│   ├── api_service.dart          [EDIT] ✏️
│   └── booking_service.dart      [NEW] ✨
└── blocs/ (optional)
    └── booking_bloc.dart         [NEW] ✨
```

---

## API Endpoints to Implement

### Booking Endpoints
```
POST   /api/bookings              - Create new booking
GET    /api/bookings              - Get all user bookings (authenticated)
GET    /api/bookings/:id          - Get specific booking
PUT    /api/bookings/:id          - Update booking
DELETE /api/bookings/:id          - Cancel booking
GET    /api/bookings/timetable/:id/seats - Get seat availability
```

### Payment Endpoints
```
POST   /api/bookings/:id/payment  - Process payment for booking
GET    /api/bookings/:id/payment  - Get payment status
POST   /api/bookings/:id/refund   - Process refund (admin)
```

---

## Database Schema Overview

### Booking Collection
```javascript
{
  _id: ObjectId,
  bookingReference: String,           // e.g., "BK-20250110-ABCD1234"
  passengerId: ObjectId,              // ref: Passenger
  timetableId: ObjectId,              // ref: BusTimeTable
  seatNumbers: [String],              // e.g., ["A1", "A2"]
  totalSeats: Number,
  bookingStatus: String,              // pending, confirmed, cancelled, completed
  journeyDate: Date,
  passengerDetails: {
    name: String,
    phone: String,
    email: String
  },
  pricing: {
    pricePerSeat: Number,
    totalAmount: Number,
    currency: String                  // default: "LKR"
  },
  paymentStatus: String,              // pending, paid, failed, refunded
  paymentId: ObjectId,                // ref: Payment
  createdAt: Date,
  updatedAt: Date
}
```

### Payment Collection
```javascript
{
  _id: ObjectId,
  bookingId: ObjectId,                // ref: Booking
  amount: Number,
  currency: String,                   // default: "LKR"
  paymentMethod: String,              // card, mobile, bank_transfer, cash
  paymentStatus: String,              // pending, completed, failed, refunded
  transactionId: String,              // mock transaction ID
  mockCardNumber: String,             // last 4 digits for testing
  processedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

---

## Implementation Order

### Phase 1: Backend Foundation (Day 1-2)
1. ✅ Create `booking.model.js`
2. ✅ Create `payment.model.js`
3. ✅ Create `mock-payment.service.js`
4. ✅ Create `booking.service.js`
5. ✅ Create `payment.service.js`
6. ✅ Create `booking.validators.js`
7. ✅ Create `booking.controllers.js`
8. ✅ Create `payment.controllers.js`
9. ✅ Create `booking.routes.js`
10. ✅ Edit `app.js` to register routes
11. ✅ Create `booking-helpers.js`

### Phase 2: Backend Testing (Day 2)
1. Test endpoints with Postman/curl
2. Verify seat availability logic
3. Test payment flow
4. Test booking cancellation

### Phase 3: Frontend Models & Services (Day 3)
1. ✅ Create `booking.dart` model
2. ✅ Create `payment.dart` model
3. ✅ Edit `api_service.dart` with booking methods
4. ✅ Create `booking_service.dart`

### Phase 4: Frontend Widgets (Day 3-4)
1. ✅ Create `seat_map_widget.dart`
2. ✅ Create `payment_method_card.dart`
3. ✅ Create `booking_card.dart`
4. ✅ Create `mock_payment_widget.dart`
5. ✅ Create `booking_receipt_widget.dart`

### Phase 5: Frontend Screens (Day 4-5)
1. ✅ Create `seat_selection_screen.dart`
2. ✅ Create `passenger_details_screen.dart`
3. ✅ Create `payment_screen.dart`
4. ✅ Create `booking_confirmation_screen.dart`
5. ✅ Create `my_bookings_screen.dart`
6. ✅ Create `booking_details_screen.dart`

### Phase 6: Integration & Testing (Day 5-6)
1. Test complete booking flow
2. Test payment scenarios
3. Test booking management
4. UI/UX refinements

---

## Key Features Per File

### Backend

#### `booking.model.js`
- Booking schema with references
- Auto-generate booking reference
- Seat validation
- Price calculation

#### `mock-payment.service.js`
- Simulate payment intents
- Test card scenarios (success/failure)
- Generate mock transaction IDs
- Instant payment processing

#### `booking.service.js`
- Check seat availability
- Create bookings with seat locking
- Calculate pricing
- Handle cancellations
- Generate booking receipts

#### `booking.controllers.js`
- CRUD operations
- Passenger-specific bookings
- Admin booking management
- Seat availability check

### Frontend

#### `seat_selection_screen.dart`
- Interactive seat grid
- Visual seat states (available/occupied/selected)
- Real-time seat count
- Price calculation display

#### `payment_screen.dart`
- Payment method selection
- Mock payment widget integration
- Payment status handling
- Error handling

#### `booking_confirmation_screen.dart`
- Display booking details
- Show booking reference
- Download/share receipt
- Navigate to bookings list

#### `my_bookings_screen.dart`
- List all bookings
- Filter by status
- Search by reference
- Quick actions (view, cancel)

---

## Navigation Flow

```
Bus Timetable Screen
    ↓ [Book Now]
Seat Selection Screen
    ↓ [Proceed]
Passenger Details Screen
    ↓ [Continue to Payment]
Payment Screen
    ↓ [Pay Now]
Booking Confirmation Screen
    ↓ [View My Bookings]
My Bookings Screen
    ↓ [View Details]
Booking Details Screen
```

---

*This document will be updated as implementation progresses.*

