# Smart Rural Transportation System

A bus booking and management system for rural transportation in Sri Lanka.

## Prerequisites

- Node.js (v16 or higher)
- Flutter (v3.9.0 or higher)
- MongoDB (Atlas or local instance)

## Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file with the following variables:
```
PORT=3000
MONGODB_URI=your_mongodb_connection_string
JWT_ACCESS_SECRET=your_access_secret
JWT_REFRESH_SECRET=your_refresh_secret
```

4. Seed the routes (optional but recommended for pricing):
```bash
node seed-routes.js
```

5. Run the backend:
```bash
npm run dev
```

The backend will run on `http://localhost:3000`

## Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the frontend:
```bash
flutter run -d web-server --web-hostname localhost --web-port 5173
```

The frontend will run on `http://localhost:5173`

## Test Accounts

**Passenger:**
- Email: test@example.com
- Password: password123

**Admin:**
- Create your own admin account through the registration screen

## Features

- Bus timetable management (Admin)
- Real-time seat availability
- KM-based dynamic pricing (43 Sri Lankan routes)
- Secure booking and payment
- Booking history
- User authentication with JWT tokens

## Tech Stack

**Backend:** Node.js, Express.js, MongoDB, Mongoose

**Frontend:** Flutter (Web)

**Authentication:** JWT with refresh tokens

