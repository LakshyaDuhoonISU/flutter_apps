# UPSC Exam Preparation App — Backend

A **Node.js + Express + MongoDB + Socket.IO** backend API for a full-featured UPSC preparation platform.

---

## 📚 Project Overview

This backend powers a comprehensive UPSC preparation platform providing:

- **Live & recorded classes** with real-time interaction (chat, polls, doubts)
- **Test series** with per-question analytics and results
- **Previous Year Questions (PYQ)** browsing and practice
- **Daily current affairs** with embedded quiz
- **Community discussion forum** with replies and upvoting
- **Topper talks** — video sessions from UPSC rank holders
- **Notes** per class for enrolled students
- **Bookmarking** of recorded classes
- **Class schedule** for enrolled students
- **Educator tools** — full CRUD for courses, topics, classes, tests, and content

---

## 🛠 Tech Stack

| Technology | Purpose                           |
| ---------- | --------------------------------- |
| Node.js    | JavaScript runtime                |
| Express.js | Web application framework         |
| MongoDB    | NoSQL database                    |
| Mongoose   | MongoDB object modeling           |
| Socket.IO  | Real-time live class interactions |
| JWT        | Authentication                    |
| bcrypt     | Password hashing                  |
| CORS       | Cross-origin resource sharing     |

---

## 📁 Folder Structure

```
backend/
│
├── config/
│   └── db.js                        # MongoDB connection
│
├── models/
│   ├── User.js                      # Students & educators
│   ├── Course.js                    # Course with topics and classes
│   ├── Topic.js                     # Chapter/topic within a course
│   ├── Class.js                     # Individual class (live or recorded)
│   ├── Test.js                      # Test series
│   ├── Question.js                  # Test questions
│   ├── TestResult.js                # Student test attempt results
│   ├── CurrentAffairs.js            # Daily current affairs with quiz
│   ├── Note.js                      # Student notes per class
│   ├── CommunityPost.js             # Community forum posts
│   ├── TopperTalk.js                # Topper talk video sessions
│   ├── PYQSet.js                    # Previous Year Question sets
│   ├── LiveChat.js                  # Live class chat messages
│   ├── LivePoll.js                  # Live class polls with votes
│   └── LiveDoubt.js                 # Live class student doubts
│
├── controllers/
│   ├── authController.js            # Register, login, me
│   ├── courseController.js          # Courses, topics, classes, notes, bookmarks, schedule
│   ├── testController.js            # Tests, questions, submit, results
│   ├── currentAffairsController.js  # Current affairs CRUD
│   ├── communityController.js       # Posts, replies, upvotes
│   ├── topperTalkController.js      # Topper talk CRUD
│   ├── pyqController.js             # PYQ questions
│   └── pyqSetController.js          # PYQ sets CRUD
│
├── routes/
│   ├── authRoutes.js
│   ├── courseRoutes.js
│   ├── testRoutes.js
│   ├── currentAffairsRoutes.js
│   ├── communityRoutes.js
│   ├── topperTalkRoutes.js
│   ├── pyqRoutes.js
│   ├── pyqSetRoutes.js
│   └── liveClassRoutes.js           # Live class data cleanup endpoints
│
├── middleware/
│   ├── authMiddleware.js            # JWT protect + optionalProtect
│   └── roleMiddleware.js            # restrictTo() role guard
│
├── socket/
│   └── liveClassHandlers.js         # All Socket.IO event handlers
│
├── server.js                        # App entry point
├── package.json
├── .env.example
└── README.md
```

---

## 💾 Database Collections

### Users

| Field               | Type   | Description                                         |
| ------------------- | ------ | --------------------------------------------------- |
| `name`              | String | Full name                                           |
| `email`             | String | Unique email                                        |
| `password`          | String | bcrypt hashed                                       |
| `role`              | String | `'student'` or `'educator'`                         |
| `subscriptionType`  | String | `'plus'`, `'individual'`, `'test-series'`, `'none'` |
| `enrolledCourses`   | Array  | Course IDs                                          |
| `bookmarkedClasses` | Array  | Class IDs                                           |

### Courses

| Field              | Type     | Description                   |
| ------------------ | -------- | ----------------------------- |
| `title`            | String   | Course title                  |
| `subject`          | String   | Subject area                  |
| `educatorId`       | ObjectId | Creator                       |
| `price`            | Number   | Price in INR                  |
| `isPlusIncluded`   | Boolean  | Included in Plus subscription |
| `enrolledStudents` | Number   | Count                         |

### Classes

| Field             | Type     | Description          |
| ----------------- | -------- | -------------------- |
| `courseId`        | ObjectId | Parent course        |
| `topicId`         | ObjectId | Parent topic         |
| `title`           | String   | Class title          |
| `videoUrl`        | String   | YouTube URL          |
| `scheduledAt`     | Date     | Start time (UTC)     |
| `durationMinutes` | Number   | Duration             |
| `description`     | String   | Optional description |

> **Live vs Recorded vs Upcoming** is determined client-side and server-side by comparing `scheduledAt + durationMinutes` against `Date.now()`. No separate `status` field is stored.

### LiveChat / LivePoll / LiveDoubt

Ephemeral collections used only during a live class window. Auto-deleted when the class ends via `setTimeout` in `liveClassHandlers.js`.

| Collection  | Key Fields                                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------------ |
| `LiveChat`  | `classId`, `userId`, `userName`, `userRole`, `message`, `isDeleted`                                                |
| `LivePoll`  | `classId`, `question`, `options[]` (text + votes), `voters[]`, `durationSeconds`, `startsAt`, `endsAt`, `isActive` |
| `LiveDoubt` | `classId`, `studentId`, `studentName`, `question`, `answer`, `status` (pending/answered)                           |

### PYQSet

| Field       | Type   | Description                          |
| ----------- | ------ | ------------------------------------ |
| `title`     | String | Set title (e.g. "UPSC Prelims 2023") |
| `year`      | Number | Exam year                            |
| `examType`  | String | Prelims / Mains                      |
| `subject`   | String | Subject                              |
| `questions` | Array  | PYQ question objects                 |

---

## 🔌 REST API Endpoints

### Auth — `/api/auth`

| Method | Path        | Access  | Description                  |
| ------ | ----------- | ------- | ---------------------------- |
| POST   | `/register` | Public  | Register student or educator |
| POST   | `/login`    | Public  | Login, returns JWT           |
| GET    | `/me`       | Private | Get current user             |

### Courses — `/api/courses`

| Method | Path                                 | Access   | Description                            |
| ------ | ------------------------------------ | -------- | -------------------------------------- |
| GET    | `/`                                  | Public   | Browse all courses (filter by subject) |
| GET    | `/:id`                               | Public   | Course detail with topics & classes    |
| POST   | `/`                                  | Educator | Create course                          |
| PUT    | `/:id`                               | Educator | Update course                          |
| DELETE | `/:id`                               | Educator | Delete course                          |
| GET    | `/my-courses`                        | Student  | Enrolled courses                       |
| GET    | `/educator/my-courses`               | Educator | Courses I created                      |
| POST   | `/:id/enroll`                        | Student  | Enroll in course                       |
| GET    | `/my-schedule`                       | Student  | Class schedule for enrolled courses    |
| GET    | `/bookmarks`                         | Student  | Bookmarked classes                     |
| POST   | `/classes/:classId/complete`         | Student  | Mark class as watched                  |
| POST   | `/classes/:classId/bookmark`         | Student  | Bookmark a class                       |
| DELETE | `/classes/:classId/bookmark`         | Student  | Remove bookmark                        |
| GET    | `/classes/:classId/notes`            | Student  | Get notes for a class                  |
| POST   | `/classes/:classId/notes`            | Student  | Add note                               |
| PUT    | `/classes/:classId/notes/:noteId`    | Student  | Edit note                              |
| DELETE | `/classes/:classId/notes/:noteId`    | Student  | Delete note                            |
| POST   | `/:courseId/topics`                  | Educator | Add topic to course                    |
| PUT    | `/:courseId/topics/:topicId`         | Educator | Edit topic                             |
| DELETE | `/:courseId/topics/:topicId`         | Educator | Delete topic                           |
| POST   | `/:courseId/topics/:topicId/classes` | Educator | Add class/video                        |
| PUT    | `/:courseId/classes/:classId`        | Educator | Edit class                             |
| DELETE | `/:courseId/classes/:classId`        | Educator | Delete class                           |

### Tests — `/api/test`

| Method | Path                    | Access   | Description                |
| ------ | ----------------------- | -------- | -------------------------- |
| GET    | `/:courseId`            | Private  | Tests for a course         |
| GET    | `/test/:id`             | Private  | Single test with questions |
| POST   | `/test/submit`          | Student  | Submit answers             |
| GET    | `/test/results/:testId` | Student  | My results for a test      |
| POST   | `/test/create`          | Educator | Create test with questions |

### PYQ Sets — `/api/pyq-sets` and `/api/pyq`

| Method | Path            | Access   | Description                   |
| ------ | --------------- | -------- | ----------------------------- |
| GET    | `/pyq-sets`     | Private  | Browse all PYQ sets           |
| GET    | `/pyq-sets/:id` | Private  | Single PYQ set with questions |
| POST   | `/pyq-sets`     | Educator | Create PYQ set                |
| PUT    | `/pyq-sets/:id` | Educator | Update PYQ set                |
| DELETE | `/pyq-sets/:id` | Educator | Delete PYQ set                |

### Current Affairs — `/api/current-affairs`

| Method | Path     | Access   | Description                    |
| ------ | -------- | -------- | ------------------------------ |
| GET    | `/today` | Public   | Today's current affairs + quiz |
| GET    | `/`      | Public   | All (filter by date/category)  |
| POST   | `/`      | Educator | Create current affairs entry   |

### Community — `/api/community`

| Method | Path              | Access   | Description                               |
| ------ | ----------------- | -------- | ----------------------------------------- |
| GET    | `/`               | Public   | All posts (filter by category, paginated) |
| GET    | `/:id`            | Public   | Single post with replies                  |
| POST   | `/`               | Private  | Create post                               |
| POST   | `/reply/:postId`  | Private  | Add reply                                 |
| POST   | `/upvote/:postId` | Private  | Toggle upvote                             |
| PUT    | `/pin/:postId`    | Educator | Pin/unpin post                            |

### Topper Talks — `/api/topper-talks`

| Method | Path   | Access   | Description                    |
| ------ | ------ | -------- | ------------------------------ |
| GET    | `/`    | Public   | All topper talks               |
| GET    | `/:id` | Public   | Single talk (increments views) |
| POST   | `/`    | Educator | Add topper talk                |
| PUT    | `/:id` | Educator | Update topper talk             |
| DELETE | `/:id` | Educator | Delete topper talk             |

### Live Class — `/api/live-class`

| Method | Path                | Access   | Description                       |
| ------ | ------------------- | -------- | --------------------------------- |
| DELETE | `/:classId/cleanup` | Educator | Delete all live data for a class  |
| POST   | `/cleanup-recorded` | Admin    | Bulk-clean data for ended classes |

---

## 🔌 Socket.IO — Live Class Events

Socket.IO runs on the same port as the HTTP server. Authentication is via JWT passed in `socket.handshake.auth.token`.

### Client → Server

| Event          | Payload                                             | Who      | Description                      |
| -------------- | --------------------------------------------------- | -------- | -------------------------------- |
| `join-class`   | `classId`                                           | All      | Join class room, receive history |
| `leave-class`  | `classId`                                           | All      | Leave room                       |
| `send-chat`    | `{ classId, message }`                              | All      | Send chat message                |
| `delete-chat`  | `{ classId, chatId }`                               | Educator | Delete a chat message            |
| `create-poll`  | `{ classId, question, options[], durationSeconds }` | Educator | Create a timed poll              |
| `vote-poll`    | `{ classId, pollId, optionIndex }`                  | Student  | Vote on active poll              |
| `raise-doubt`  | `{ classId, question }`                             | Student  | Submit a doubt                   |
| `answer-doubt` | `{ classId, doubtId, answer }`                      | Educator | Answer a doubt                   |
| `delete-doubt` | `{ classId, doubtId }`                              | Educator | Delete a doubt                   |

### Server → Client

| Event                        | Recipient          | Description                         |
| ---------------------------- | ------------------ | ----------------------------------- |
| `chat-history`               | Joiner             | Existing messages on join           |
| `new-chat`                   | Room               | New chat broadcast                  |
| `chat-deleted`               | Room               | Chat deletion notification          |
| `polls-history`              | Joiner             | All polls (active + ended)          |
| `new-poll`                   | Room               | New poll (students: no vote counts) |
| `poll-created`               | Educator only      | Full poll data on creation          |
| `poll-update`                | Educators          | Live vote counts while active       |
| `poll-ended`                 | Room               | Poll timer expired                  |
| `poll-results`               | Educators          | Final results after poll ends       |
| `vote-recorded`              | Voter              | Confirmation                        |
| `doubts-list`                | Joiner             | Existing doubts on join             |
| `new-doubt` / `doubt-raised` | Educator / Student | New doubt notifications             |
| `doubt-answered`             | Room               | Student sees answer                 |
| `doubt-answer-recorded`      | Educators          | Educator doubt list update          |
| `doubt-deleted`              | Room               | Doubt removed                       |
| `class-ended`                | Room               | Class ended, data cleaned up        |
| `error`                      | Sender             | Error message                       |

**Auto-cleanup:** When a class ends (`scheduledAt + durationMinutes`), a `setTimeout` deletes all LiveChat, LivePoll, and LiveDoubt documents and emits `class-ended` to all connected clients in the room.

---

## 🚀 Running Locally

### Prerequisites

- Node.js v14+
- MongoDB (local or Atlas)

### Steps

```bash
cd backend
npm install
cp .env.example .env   # then edit .env
npm run dev
```

### `.env`

```env
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb://localhost:27017/upsc_exam_app
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRE=30d
```

Server starts on **http://localhost:3000**. Socket.IO is available on the same port.

---

## 🔐 Authentication

All protected REST routes require:

```
Authorization: Bearer <jwt_token>
```

Socket.IO connections require the token in the handshake:

```js
IO.io(url, { auth: { token: "<jwt_token>" } });
```

---

## ✅ Implemented Features

- User auth (register, login, JWT)
- Role-based access control (student / educator)
- Full course management (CRUD, topics, classes)
- Class progress tracking (mark completed, bookmarks)
- Personal notes per class
- Class schedule for enrolled students
- Test series with question bank and analytics
- Previous Year Questions (PYQ sets)
- Daily current affairs with quiz
- Community forum (posts, replies, upvotes, pin)
- Topper talks video library
- Real-time live class interactions via Socket.IO
  - Live chat with educator moderation
  - Timed polls with live vote counts and history
  - Student doubts with educator answers
  - Auto-cleanup on class end

A complete **Node.js + Express + MongoDB** backend API for a UPSC preparation Flutter app. This is a college project designed to be simple, clean, and easy to understand while following proper backend development practices.

---

## 📚 Project Overview

This backend powers a comprehensive UPSC preparation platform similar to Unacademy, providing features for:

- Live and recorded classes
- Test series with detailed analysis
- Daily current affairs with quiz
- Community discussion forums
- Notes and bookmarking
- Topper talks and success stories

---

## 🛠 Tech Stack

- **Node.js** - JavaScript runtime
- **Express.js** - Web application framework
- **MongoDB** - NoSQL database
- **Mongoose** - MongoDB object modeling
- **JWT** - Authentication using JSON Web Tokens
- **bcrypt** - Password hashing
- **CORS** - Cross-origin resource sharing

---

## 📁 Folder Structure

```
backend/
│
├── config/
│   └── db.js                    # MongoDB connection configuration
│
├── models/                      # Database models (Mongoose schemas)
│   ├── User.js                  # User model (students & educators)
│   ├── Course.js                # Course model
│   ├── Topic.js                 # Topic/Chapter model
│   ├── Class.js                 # Class model (live/recorded)
│   ├── Test.js                  # Test model
│   ├── Question.js              # Question model for tests
│   ├── TestResult.js            # Test results model
│   ├── CurrentAffairs.js        # Daily current affairs model
│   ├── Note.js                  # Student notes model
│   ├── CommunityPost.js         # Community forum post model
│   └── TopperTalk.js            # Topper talk session model
│
├── controllers/                 # Business logic handlers
│   ├── authController.js        # Authentication logic
│   ├── courseController.js      # Course management logic
│   ├── testController.js        # Test series logic
│   ├── currentAffairsController.js  # Current affairs logic
│   └── communityController.js   # Community forum logic
│
├── routes/                      # API route definitions
│   ├── authRoutes.js            # Auth endpoints
│   ├── courseRoutes.js          # Course endpoints
│   ├── testRoutes.js            # Test endpoints
│   ├── currentAffairsRoutes.js  # Current affairs endpoints
│   └── communityRoutes.js       # Community endpoints
│
├── middleware/                  # Custom middleware
│   ├── authMiddleware.js        # JWT authentication
│   └── roleMiddleware.js        # Role-based access control
│
├── server.js                    # Main server entry point
├── package.json                 # Project dependencies
├── .env.example                 # Environment variables template
├── .gitignore                   # Git ignore file
└── README.md                    # This file
```

---

## 💾 Database Collections

### 1. **Users**

Stores information about students and educators.

| Field              | Type   | Description                                    |
| ------------------ | ------ | ---------------------------------------------- |
| `name`             | String | User's full name                               |
| `email`            | String | Email address (unique)                         |
| `password`         | String | Hashed password                                |
| `role`             | String | 'student' or 'educator'                        |
| `subscriptionType` | String | 'plus', 'individual', 'test-series', or 'none' |
| `enrolledCourses`  | Array  | Array of course IDs                            |
| `createdAt`        | Date   | Account creation timestamp                     |

### 2. **Courses**

Represents courses created by educators.

| Field              | Type     | Description                        |
| ------------------ | -------- | ---------------------------------- |
| `title`            | String   | Course title                       |
| `subject`          | String   | Subject (History, Geography, etc.) |
| `description`      | String   | Course description                 |
| `educatorId`       | ObjectId | Reference to User (educator)       |
| `price`            | Number   | Course price in INR                |
| `isPlusIncluded`   | Boolean  | Included in Plus subscription      |
| `syllabusTopics`   | Array    | Array of Topic IDs                 |
| `enrolledStudents` | Number   | Count of enrolled students         |
| `thumbnail`        | String   | Course thumbnail URL               |
| `createdAt`        | Date     | Creation timestamp                 |

### 3. **Topics**

Represents topics/chapters within a course.

| Field            | Type     | Description               |
| ---------------- | -------- | ------------------------- |
| `courseId`       | ObjectId | Reference to Course       |
| `title`          | String   | Topic title               |
| `description`    | String   | Topic description         |
| `orderIndex`     | Number   | Display order in syllabus |
| `estimatedHours` | Number   | Estimated completion time |
| `createdAt`      | Date     | Creation timestamp        |

### 4. **Classes**

Represents individual classes (live or recorded).

| Field             | Type     | Description          |
| ----------------- | -------- | -------------------- |
| `courseId`        | ObjectId | Reference to Course  |
| `topicId`         | ObjectId | Reference to Topic   |
| `title`           | String   | Class title          |
| `type`            | String   | 'live' or 'recorded' |
| `scheduledAt`     | Date     | Scheduled date/time  |
| `videoUrl`        | String   | Video URL            |
| `durationMinutes` | Number   | Class duration       |
| `isCompleted`     | Boolean  | Completion status    |
| `description`     | String   | Class description    |
| `createdAt`       | Date     | Creation timestamp   |

### 5. **Tests**

Represents test series/mock tests.

| Field             | Type     | Description                  |
| ----------------- | -------- | ---------------------------- |
| `courseId`        | ObjectId | Reference to Course          |
| `title`           | String   | Test title                   |
| `description`     | String   | Test description             |
| `durationMinutes` | Number   | Test duration                |
| `totalQuestions`  | Number   | Number of questions          |
| `totalMarks`      | Number   | Total marks                  |
| `createdBy`       | ObjectId | Reference to User (educator) |
| `isFree`          | Boolean  | Free or paid test            |
| `createdAt`       | Date     | Creation timestamp           |

### 6. **Questions**

Stores individual questions for tests.

| Field            | Type     | Description                   |
| ---------------- | -------- | ----------------------------- |
| `testId`         | ObjectId | Reference to Test             |
| `topicId`        | ObjectId | Reference to Topic            |
| `question`       | String   | Question text                 |
| `options`        | Array    | 4 answer options              |
| `correctAnswer`  | Number   | Index of correct option (0-3) |
| `explanation`    | String   | Answer explanation            |
| `difficulty`     | String   | 'Easy', 'Medium', or 'Hard'   |
| `marks`          | Number   | Marks for this question       |
| `isPreviousYear` | Boolean  | Previous year question        |
| `year`           | Number   | Year (if previous year)       |
| `createdAt`      | Date     | Creation timestamp            |

### 7. **TestResults**

Stores test attempt results.

| Field              | Type     | Description                     |
| ------------------ | -------- | ------------------------------- |
| `userId`           | ObjectId | Reference to User               |
| `testId`           | ObjectId | Reference to Test               |
| `answers`          | Array    | Array of answer objects         |
| `score`            | Number   | Total score obtained            |
| `correctCount`     | Number   | Number of correct answers       |
| `wrongCount`       | Number   | Number of wrong answers         |
| `unattemptedCount` | Number   | Number of unattempted questions |
| `accuracy`         | Number   | Accuracy percentage             |
| `totalTimeTaken`   | Number   | Time taken in minutes           |
| `attemptedAt`      | Date     | Attempt timestamp               |

### 8. **CurrentAffairs**

Stores daily current affairs with quiz.

| Field       | Type     | Description                              |
| ----------- | -------- | ---------------------------------------- |
| `date`      | Date     | Date of current affairs                  |
| `title`     | String   | Title                                    |
| `summary`   | String   | Content/summary                          |
| `quiz`      | Array    | Array of quiz questions                  |
| `category`  | String   | Category (National, International, etc.) |
| `imageUrl`  | String   | Image URL                                |
| `createdBy` | ObjectId | Reference to User (educator)             |
| `createdAt` | Date     | Creation timestamp                       |

### 9. **Notes**

Stores personal notes created by students.

| Field        | Type     | Description                     |
| ------------ | -------- | ------------------------------- |
| `userId`     | ObjectId | Reference to User               |
| `courseId`   | ObjectId | Reference to Course             |
| `topicId`    | ObjectId | Reference to Topic              |
| `title`      | String   | Note title                      |
| `content`    | String   | Note content (can include HTML) |
| `bookmarked` | Boolean  | Bookmark status                 |
| `tags`       | Array    | Tags for organization           |
| `createdAt`  | Date     | Creation timestamp              |
| `updatedAt`  | Date     | Last update timestamp           |

### 10. **CommunityPosts**

Represents posts in the community forum.

| Field       | Type     | Description            |
| ----------- | -------- | ---------------------- |
| `title`     | String   | Post title             |
| `content`   | String   | Post content           |
| `createdBy` | ObjectId | Reference to User      |
| `category`  | String   | Post category          |
| `replies`   | Array    | Array of reply objects |
| `upvotes`   | Number   | Number of upvotes      |
| `upvotedBy` | Array    | Users who upvoted      |
| `isPinned`  | Boolean  | Pinned by moderator    |
| `isLocked`  | Boolean  | Locked for replies     |
| `createdAt` | Date     | Creation timestamp     |

### 11. **TopperTalks**

Stores videos/sessions from UPSC toppers.

| Field             | Type    | Description         |
| ----------------- | ------- | ------------------- |
| `title`           | String  | Session title       |
| `topperName`      | String  | Topper's name       |
| `rank`            | Number  | Rank achieved       |
| `year`            | Number  | Year of exam        |
| `optional`        | String  | Optional subject    |
| `videoUrl`        | String  | Video URL           |
| `thumbnail`       | String  | Thumbnail URL       |
| `durationMinutes` | Number  | Video duration      |
| `isFree`          | Boolean | Free access         |
| `description`     | String  | Session description |
| `views`           | Number  | View count          |
| `createdAt`       | Date    | Creation timestamp  |

---

## 🔌 API Endpoints

### **Authentication Routes** (`/api/auth`)

#### 1. Register User

```
POST /api/auth/register
```

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "student"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "_id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "student",
    "subscriptionType": "none",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 2. Login User

```
POST /api/auth/login
```

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "_id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "student",
    "subscriptionType": "none",
    "enrolledCourses": [],
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 3. Get Current User

```
GET /api/auth/me
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "_id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "student",
    "subscriptionType": "none",
    "enrolledCourses": [...]
  }
}
```

---

### **Course Routes** (`/api/courses`)

#### 1. Get All Courses

```
GET /api/courses
Query Params: ?subject=History&isPlusIncluded=true
```

**Response (200):**

```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "_id": "...",
      "title": "Ancient Indian History",
      "subject": "History",
      "description": "Complete ancient history coverage",
      "price": 2499,
      "isPlusIncluded": true,
      "enrolledStudents": 1500,
      "educatorId": {
        "name": "Dr. Sharma",
        "email": "sharma@example.com"
      },
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### 2. Get Single Course

```
GET /api/courses/:id
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "course": { ... },
    "topics": [ ... ],
    "classes": [ ... ]
  }
}
```

#### 3. Create Course (Educator Only)

```
POST /api/courses
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "title": "Ancient Indian History",
  "subject": "History",
  "description": "Complete course on ancient Indian history",
  "price": 2499,
  "isPlusIncluded": true
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Course created successfully",
  "data": { ... }
}
```

#### 4. Enroll in Course

```
POST /api/courses/:id/enroll
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Successfully enrolled in course",
  "data": {
    "courseId": "...",
    "courseTitle": "Ancient Indian History"
  }
}
```

#### 5. Get My Enrolled Courses

```
GET /api/courses/my-courses
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "count": 3,
  "data": [ ... ]
}
```

---

### **Test Routes** (`/api/tests`)

#### 1. Get Tests by Course

```
GET /api/tests/:courseId
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "_id": "...",
      "title": "Ancient History Mock Test 1",
      "durationMinutes": 120,
      "totalQuestions": 100,
      "totalMarks": 200,
      "isFree": false,
      "createdAt": "2024-01-20T10:00:00Z"
    }
  ]
}
```

#### 2. Get Single Test

```
GET /api/tests/test/:id
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "test": { ... },
    "questions": [
      {
        "_id": "...",
        "question": "Who was the founder of Maurya Empire?",
        "options": [
          "Chandragupta Maurya",
          "Ashoka",
          "Bindusara",
          "Samudragupta"
        ],
        "difficulty": "Easy",
        "marks": 2
      }
    ]
  }
}
```

#### 3. Submit Test

```
POST /api/tests/test/submit
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "testId": "...",
  "totalTimeTaken": 105,
  "answers": [
    {
      "questionId": "...",
      "selectedOption": 0,
      "timeTaken": 30
    }
  ]
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Test submitted successfully",
  "data": {
    "score": 180,
    "correctCount": 90,
    "wrongCount": 8,
    "unattemptedCount": 2,
    "accuracy": "91.84",
    "answers": [ ... ]
  }
}
```

#### 4. Get Test Results

```
GET /api/tests/test/results/:testId
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "count": 2,
  "data": [ ... ]
}
```

#### 5. Create Test (Educator Only)

```
POST /api/tests/test/create
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "courseId": "...",
  "title": "Mock Test 1",
  "description": "First mock test",
  "durationMinutes": 120,
  "totalMarks": 200,
  "questions": [
    {
      "question": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 0,
      "explanation": "Explanation here",
      "difficulty": "Medium",
      "marks": 2
    }
  ]
}
```

---

### **Current Affairs Routes** (`/api/current-affairs`)

#### 1. Get Today's Current Affairs

```
GET /api/current-affairs/today
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "_id": "...",
    "date": "2024-03-02T00:00:00Z",
    "title": "Daily Current Affairs - March 2, 2024",
    "summary": "Today's important news and updates...",
    "category": "National",
    "quiz": [
      {
        "question": "Who was appointed as the new Chief Justice of India?",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correctAnswer": 1,
        "explanation": "Explanation here"
      }
    ],
    "imageUrl": "...",
    "createdAt": "2024-03-02T06:00:00Z"
  }
}
```

#### 2. Get Current Affairs (with filters)

```
GET /api/current-affairs
Query Params: ?startDate=2024-01-01&endDate=2024-01-31&category=National
```

**Response (200):**

```json
{
  "success": true,
  "count": 30,
  "data": [ ... ]
}
```

#### 3. Create Current Affairs (Educator Only)

```
POST /api/current-affairs
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "date": "2024-03-02",
  "title": "Daily Current Affairs - March 2, 2024",
  "summary": "Summary of the day's events...",
  "category": "National",
  "quiz": [
    {
      "question": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 1,
      "explanation": "Explanation"
    }
  ]
}
```

---

### **Community Routes** (`/api/community`)

#### 1. Get All Posts

```
GET /api/community
Query Params: ?category=Doubt&page=1&limit=20
```

**Response (200):**

```json
{
  "success": true,
  "count": 20,
  "total": 150,
  "page": 1,
  "pages": 8,
  "data": [
    {
      "_id": "...",
      "title": "How to prepare Modern History?",
      "content": "I need suggestions on...",
      "category": "Doubt",
      "createdBy": {
        "name": "Student Name",
        "role": "student"
      },
      "replies": [ ... ],
      "upvotes": 25,
      "isPinned": false,
      "createdAt": "2024-03-01T10:00:00Z"
    }
  ]
}
```

#### 2. Get Single Post

```
GET /api/community/:id
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "_id": "...",
    "title": "How to prepare Modern History?",
    "content": "I need suggestions on...",
    "replies": [
      {
        "userId": {
          "name": "Educator Name",
          "role": "educator"
        },
        "message": "Here are my suggestions...",
        "createdAt": "2024-03-01T11:00:00Z"
      }
    ],
    "upvotes": 25
  }
}
```

#### 3. Create Post

```
POST /api/community
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "title": "How to prepare Modern History?",
  "content": "I need suggestions on preparing modern Indian history for UPSC prelims. What resources should I use?",
  "category": "Doubt"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Post created successfully",
  "data": { ... }
}
```

#### 4. Add Reply to Post

```
POST /api/community/reply/:postId
Headers: Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "message": "Here are my suggestions: 1) Read NCERT first..."
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Reply added successfully",
  "data": { ... }
}
```

#### 5. Upvote Post

```
POST /api/community/upvote/:postId
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Post upvoted",
  "data": {
    "upvotes": 26,
    "upvoted": true
  }
}
```

#### 6. Pin/Unpin Post (Educator Only)

```
PUT /api/community/pin/:postId
Headers: Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Post pinned",
  "data": { ... }
}
```

---

## 🚀 How to Run Locally

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (local installation or MongoDB Atlas account)
- npm or yarn package manager

### Installation Steps

1. **Clone the repository**

```bash
cd backend
```

2. **Install dependencies**

```bash
npm install
```

3. **Create environment file**

```bash
cp .env.example .env
```

4. **Configure environment variables**

Edit `.env` file:

```env
PORT=5000
NODE_ENV=development
MONGO_URI=mongodb://localhost:27017/upsc_exam_app
JWT_SECRET=your_super_secret_jwt_key_change_this
JWT_EXPIRE=30d
```

**For MongoDB Atlas:**

```env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/upsc_exam_app?retryWrites=true&w=majority
```

5. **Start MongoDB**

If using local MongoDB:

```bash
mongod
```

If using MongoDB Atlas, skip this step.

6. **Run the server**

Development mode (with auto-restart):

```bash
npm run dev
```

Production mode:

```bash
npm start
```

7. **Verify server is running**

You should see:

```
🚀 Server is running on port 5000
📍 Environment: development
🔗 API URL: http://localhost:5000
MongoDB Connected: ...
```

8. **Test the API**

Open browser or Postman and visit:

```
http://localhost:5000
```

You should see the API welcome message with available endpoints.

---

## 📝 Sample .env Structure

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# MongoDB Connection String
# Option 1: Local MongoDB
MONGO_URI=mongodb://localhost:27017/upsc_exam_app

# Option 2: MongoDB Atlas (Cloud)
# MONGO_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority

# JWT Secret Key
# Generate a secure random string for production
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# JWT Token Expiry
# Examples: '1h', '7d', '30d'
JWT_EXPIRE=30d
```

---

## 🧪 Testing the API

### Using Postman

1. **Register a new student**
   - POST `http://localhost:5000/api/auth/register`
   - Body: `{ "name": "Test Student", "email": "student@test.com", "password": "123456", "role": "student" }`

2. **Login**
   - POST `http://localhost:5000/api/auth/login`
   - Body: `{ "email": "student@test.com", "password": "123456" }`
   - Copy the `token` from response

3. **Access protected routes**
   - GET `http://localhost:5000/api/auth/me`
   - Headers: `Authorization: Bearer <your-token>`

### Using cURL

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"123456","role":"student"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'
```

---

## 🔐 Authentication

This API uses **JWT (JSON Web Tokens)** for authentication.

### How it works:

1. User registers or logs in
2. Server generates a JWT token
3. Client stores the token (in Flutter app, use secure storage)
4. Client sends token in Authorization header for protected routes:
   ```
   Authorization: Bearer <token>
   ```

### Protected Routes:

- All routes except registration, login, and public course viewing require authentication
- Some routes (like creating courses, creating tests) require educator role

---

## 📱 Connecting with Flutter App

### Base URL Configuration

In your Flutter app, set the base URL:

```dart
// For Android Emulator
final String baseUrl = 'http://10.0.2.2:5000/api';

// For iOS Simulator
final String baseUrl = 'http://localhost:5000/api';

// For Physical Device (use your computer's IP)
final String baseUrl = 'http://192.168.1.x:5000/api';

// For Production
final String baseUrl = 'https://your-api-domain.com/api';
```

### Example API Call in Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to login');
  }
}
```

---

## 🎯 Features Implemented

✅ User registration and authentication (JWT)  
✅ Role-based access control (Student/Educator)  
✅ Course management (CRUD operations)  
✅ Topic and class management  
✅ Test series with questions  
✅ Test submission and results with analytics  
✅ Daily current affairs with quiz  
✅ Community forum with posts and replies  
✅ Upvoting system  
✅ Pin posts (moderator feature)  
✅ Course enrollment system  
✅ Password hashing with bcrypt  
✅ Error handling and validation  
✅ MongoDB indexing for performance

---

## 📈 Future Enhancements

- [ ] File upload for course thumbnails and videos
- [ ] Payment gateway integration
- [ ] Email notifications
- [ ] Real-time chat for live classes
- [ ] Video streaming support
- [ ] Analytics dashboard for educators
- [ ] Push notifications
- [ ] Advanced search and filtering
- [ ] Rate limiting and security enhancements
- [ ] API documentation with Swagger

---

## 🐛 Common Issues & Solutions

### Issue 1: MongoDB Connection Error

**Error:** `MongooseServerSelectionError: connect ECONNREFUSED 127.0.0.1:27017`

**Solution:**

- Make sure MongoDB is running: `mongod`
- Check if `MONGO_URI` in `.env` is correct

### Issue 2: JWT Token Invalid

**Error:** `Not authorized, token failed`

**Solution:**

- Check if token is being sent correctly in headers
- Verify `JWT_SECRET` matches between token generation and verification
- Check if token has expired

### Issue 3: CORS Error

**Error:** `Access to fetch blocked by CORS policy`

**Solution:**

- Server already has CORS enabled
- If still facing issues, check if your Flutter app is sending correct headers

---

## 👨‍💻 Development Tips

1. **Use Postman Collection**: Create a Postman collection for all endpoints
2. **Environment Variables**: Never commit `.env` file to Git
3. **Error Logs**: Check server console for detailed error messages
4. **Database GUI**: Use MongoDB Compass to visualize your database
5. **Code Organization**: Keep controllers focused on business logic
6. **Comments**: Code is well-commented for easy understanding

---

## 📚 Learning Resources

- [Express.js Documentation](https://expressjs.com/)
- [Mongoose Documentation](https://mongoosejs.com/)
- [JWT Introduction](https://jwt.io/introduction)
- [MongoDB University](https://university.mongodb.com/)
- [REST API Best Practices](https://restfulapi.net/)

---

## 📄 License

This project is created for educational purposes as a college project.

---

## 📞 Support

For any issues or questions:

- Check the API documentation above
- Review error messages in server console
- Test endpoints using Postman
- Verify MongoDB connection

---

## 🎓 Project Notes

This backend is designed as a **college project** for learning purposes. It follows industry-standard practices while maintaining simplicity and readability. The code is well-commented to help understand the flow and logic.

**Key Learning Outcomes:**

- RESTful API design
- JWT authentication
- MongoDB and Mongoose
- Error handling
- Middleware concepts
- Role-based access control
- Async/await patterns
- MVC architecture

---

**Happy Coding! 🚀**
