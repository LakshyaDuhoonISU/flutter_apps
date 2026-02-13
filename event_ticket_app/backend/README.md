# Event Ticket Booking System - Backend API

A complete RESTful API for an online event management and ticket booking system built with Node.js, Express, MongoDB, and JWT authentication.

## Features

- **User Authentication**: Secure registration and login with bcrypt password hashing and JWT tokens
- **Role-Based Access Control**: Three user roles (user, organizer, admin) with different permissions
- **Event Management**: Create, read, update, and delete events (organizer only)
- **Ticket Booking**: Book tickets with automatic availability checking and atomic operations
- **Admin Analytics**: Comprehensive statistics using MongoDB aggregation pipelines
- **Data Validation**: Input validation and error handling
- **Security**: Protected routes with JWT authentication

## Tech Stack

- Node.js & Express.js
- MongoDB & Mongoose
- JWT (JSON Web Tokens)
- bcryptjs for password hashing
- CORS enabled

## Installation

1. Install dependencies:

```bash
cd backend
npm install
```

2. Make sure MongoDB is running on `localhost:27017`

3. Start the server:

```bash
npm start
```

The server will run on `http://localhost:3000`

## User Roles

- **user**: Can view events and book tickets
- **organizer**: Can create, update, delete events and view bookings for their events
- **admin**: Can view all events, bookings, and access analytics

## API Endpoints

### Authentication

#### Register User

```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "user"
}
```

**Response:**

```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user"
  }
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user"
  }
}
```

### Events

#### Create Event (Organizer Only)

```http
POST /api/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Tech Conference 2026",
  "description": "Annual technology conference",
  "date": "2026-06-15T10:00:00.000Z",
  "imageUrl": "https://example.com/image.jpg",
  "location": "San Francisco, CA",
  "totalTickets": 500,
  "price": 99.99
}
```

#### Get All Events (Public)

```http
GET /api/events
```

**Returns all events sorted by date**

#### Get My Events (Organizer Only)

```http
GET /api/events/my-events
Authorization: Bearer <token>
```

**Returns only the events created by the authenticated organizer**

#### Get Single Event

```http
GET /api/events/:id
```

#### Update Event (Organizer Only - Own Events)

```http
PUT /api/events/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated Title",
  "description": "Updated description",
  "date": "2026-07-20T15:00:00.000Z",
  "imageUrl": "https://example.com/new-image.jpg",
  "location": "New Location",
  "totalTickets": 600,
  "price": 175.00
}
```

**Note:** totalTickets cannot be reduced below the number of tickets already sold

#### Delete Event (Organizer Only - Own Events)

```http
DELETE /api/events/:id
Authorization: Bearer <token>
```

### Bookings

#### Create Booking (User Only)

```http
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "eventId": "event_id_here",
  "numberOfTickets": 2
}
```

**Features:**

- Checks ticket availability before booking
- Atomically reduces availableTickets
- Prevents overbooking with concurrent requests
- Returns error if insufficient tickets

#### Get My Bookings (User Only)

```http
GET /api/bookings/my
Authorization: Bearer <token>
```

#### Get Event Bookings (Organizer Only - Own Events)

```http
GET /api/bookings/event/:id
Authorization: Bearer <token>
```

**Response includes:**

- List of all bookings
- Total tickets sold
- Total revenue

### Admin

#### Get All Events (Admin Only)

```http
GET /api/admin/events
Authorization: Bearer <token>
```

Returns all events with organizer information

#### Update Any Event (Admin Only)

```http
PUT /api/admin/events/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated by Admin",
  "price": 200.00
}
```

**Admins can update any event, not just their own**

#### Delete Any Event (Admin Only)

```http
DELETE /api/admin/events/:id
Authorization: Bearer <token>
```

**Admins can delete any event, not just their own**

#### Get All Bookings (Admin Only)

```http
GET /api/admin/bookings
Authorization: Bearer <token>
```

#### Get Analytics (Admin Only)

```http
GET /api/admin/stats
Authorization: Bearer <token>
```

**Response includes:**

```json
{
  "success": true,
  "analytics": {
    "overview": {
      "totalEvents": 10,
      "totalBookings": 45,
      "totalTicketsSold": 123,
      "totalRevenue": 12345.67
    },
    "eventStats": [
      {
        "eventId": "...",
        "eventTitle": "Tech Conference 2026",
        "totalTicketsSold": 50,
        "totalBookings": 25,
        "price": 99.99,
        "revenue": 4999.5
      }
    ],
    "topUsers": [
      {
        "userId": "...",
        "userName": "John Doe",
        "userEmail": "john@example.com",
        "totalBookings": 5,
        "totalTickets": 12
      }
    ]
  }
}
```

## Ticket Booking Logic

The system implements robust ticket booking with the following features:

1. **Availability Check**: Verifies sufficient tickets before booking
2. **Atomic Operations**: Uses MongoDB `findOneAndUpdate` with conditions to prevent race conditions
3. **Ticket Reduction**: Automatically decrements `availableTickets` when booking succeeds
4. **Rejection Handling**: Returns error if tickets are insufficient or already booked

```javascript
// Atomic update ensures no overbooking
const updatedEvent = await Event.findOneAndUpdate(
  {
    _id: eventId,
    availableTickets: { $gte: numberOfTickets },
  },
  {
    $inc: { availableTickets: -numberOfTickets },
  },
  { new: true },
);
```

## Analytics Implementation

Admin analytics use MongoDB aggregation pipelines for efficient data processing:

### 1. Total Tickets Sold Per Event

```javascript
await Booking.aggregate([
  {
    $group: {
      _id: "$event",
      totalTicketsSold: { $sum: "$numberOfTickets" },
    },
  },
]);
```

### 2. Revenue Per Event

```javascript
await Booking.aggregate([
  {
    $lookup: {
      from: "events",
      localField: "event",
      foreignField: "_id",
      as: "eventInfo",
    },
  },
  {
    $group: {
      _id: "$event",
      totalRevenue: {
        $sum: { $multiply: ["$numberOfTickets", "$eventInfo.price"] },
      },
    },
  },
]);
```

### 3. Top Users by Bookings

```javascript
await Booking.aggregate([
  {
    $group: {
      _id: "$user",
      totalBookings: { $sum: 1 },
      totalTickets: { $sum: "$numberOfTickets" },
    },
  },
  { $sort: { totalBookings: -1 } },
  { $limit: 10 },
]);
```

## Error Handling

All endpoints include comprehensive error handling:

- **400**: Bad request (validation errors)
- **401**: Unauthorized (no token or invalid token)
- **403**: Forbidden (insufficient permissions)
- **404**: Not found
- **500**: Internal server error

## Security Features

- **Password Hashing**: bcrypt with 10 salt rounds
- **JWT Tokens**: 7-day expiration
- **Role-Based Access**: Middleware enforces permissions
- **Input Validation**: All requests validated
- **Atomic Operations**: Prevents race conditions in booking
- **Organizer Ownership**: Organizers can only modify/delete their own events
- **Ticket Constraints**: Cannot reduce total tickets below already sold tickets

## Testing the API

### 1. Register Users

```bash
# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"User One","email":"user@test.com","password":"pass123","role":"user"}'

# Register an organizer
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Organizer One","email":"org@test.com","password":"pass123","role":"organizer"}'

# Register an admin
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin","email":"admin@test.com","password":"pass123","role":"admin"}'
```

### 2. Login and Get Token

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"org@test.com","password":"pass123"}'
```

### 3. Create Event (use organizer token)

```bash
curl -X POST http://localhost:3000/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ORGANIZER_TOKEN" \
  -d '{
    "title":"Music Festival 2026",
    "description":"Amazing music festival",
    "date":"2026-08-20T18:00:00.000Z",
    "imageUrl":"https://example.com/festival.jpg",
    "location":"New York, NY",
    "totalTickets":1000,
    "price":150
  }'
```

### 4. Update Event

```bash
curl -X PUT http://localhost:3000/api/events/EVENT_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ORGANIZER_TOKEN" \
  -d '{
    "title":"Updated Music Festival 2026",
    "price":175
  }'
```

### 5. Book Tickets (use user token)

```bash
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -d '{"eventId":"EVENT_ID","numberOfTickets":2}'
```

### 6. Get Analytics (use admin token)

```bash
curl -X GET http://localhost:3000/api/admin/stats \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## Project Structure

```
backend/
├── middleware/
│   └── auth.js              # JWT authentication & authorization
├── models/
│   ├── Booking.js           # Booking schema
│   ├── Event.js             # Event schema
│   └── User.js              # User schema
├── routes/
│   ├── adminRoutes.js       # Admin endpoints
│   ├── authRoutes.js        # Authentication endpoints
│   ├── bookingRoutes.js     # Booking endpoints
│   └── eventRoutes.js       # Event endpoints
├── db.js                    # Database connection
├── server.js                # Express server setup
└── package.json             # Dependencies
```

## Development Notes

- All passwords are hashed using bcrypt before storage
- JWT tokens include user ID, email, and role
- MongoDB connection string: `mongodb://localhost:27017/event-booking`
- Events include organizer reference and attendees array
- Organizers can only modify/delete their own events
- Admins can modify/delete any event
- Users can only create bookings (not organizers or admins)
- Total tickets can be increased but not reduced below tickets already sold

## Future Enhancements

- Payment integration
- Email notifications
- Ticket cancellation
- Event categories/tags
- Search and filtering
- Rate limiting
- Environment variables for configuration
- Unit and integration tests

## License

ISC
