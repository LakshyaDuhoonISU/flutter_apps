# UPSC Exam Preparation App

A full-stack UPSC preparation platform with live classes, tests, PYQs, current affairs, and community features.

## Stack

| Layer    | Tech                        |
| -------- | --------------------------- |
| Frontend | Flutter (web + mobile)      |
| Backend  | Node.js + Express + MongoDB |
| Realtime | Socket.IO                   |
| Auth     | JWT                         |

## Features

- **Live Classes** — real-time chat, timed polls, and student doubts via Socket.IO
- **Recorded Classes** — watch at any time; mark complete, bookmark, take notes
- **Class Schedule** — daily schedule view for enrolled courses
- **Test Series** — timed tests with per-question result analysis
- **Previous Year Questions** — browse and practice PYQ sets
- **Current Affairs** — daily articles with embedded quiz
- **Community Forum** — posts, replies, upvotes
- **Topper Talks** — video sessions from UPSC rank holders
- **Educator Tools** — manage courses, topics, classes, tests, polls, and doubts live
- **Subscriptions** — multiple plans (Plus, Individual, Test-Series)

---

## Installation

### Prerequisites

- Node.js v14+
- MongoDB (local or Atlas)
- Flutter SDK 3.x

### 1. Clone

```bash
git clone <repo-url>
cd upsc_exam_app
```

### 2. Backend

```bash
cd backend
npm install
cp .env.example .env   # fill in MONGO_URI and JWT_SECRET
npm run dev            # starts on http://localhost:3000
```

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome  # recommended — Socket.IO works best on web
```

> For a physical device, update `baseUrl` and `socketBaseUrl` in `frontend/lib/utils/constants.dart` to your machine's LAN IP.

---

## Environment Variables (backend `.env`)

```env
PORT=3000
MONGO_URI=mongodb://localhost:27017/upsc_exam_app
JWT_SECRET=your_secret_here
JWT_EXPIRE=30d
```

---

## Troubleshooting

| Problem                                | Fix                                                                                      |
| -------------------------------------- | ---------------------------------------------------------------------------------------- |
| `Connection refused` on frontend       | Make sure backend is running on port 3000                                                |
| Socket not connecting on mobile        | Replace `localhost` with LAN IP in `constants.dart`                                      |
| `flutter pub get` fails                | Run `flutter upgrade` then retry                                                         |
| MongoDB connection error               | Check `MONGO_URI` in `.env`; ensure mongod is running                                    |
| Old user's socket data persisting      | Auth bug is handled — logout calls `SocketService.disconnect()` and clears cached socket |
| Live poll history missing after rejoin | Handled — backend sends `polls-history` on `join-class`                                  |

---

See [`backend/README.md`](backend/README.md) for full API and Socket.IO event documentation.  
See [`frontend/README.md`](frontend/README.md) for full screen and service documentation.
