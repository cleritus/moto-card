# Moto Service Card API

Backend API for the Moto Service Card mobile application.

## Tech Stack

- **Runtime**: Node.js 24+
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: MongoDB Atlas (Mongoose ODM)
- **Authentication**: JWT (Access + Refresh tokens)

## Project Structure

```
api/
├── src/
│   ├── config/           # Database and app configuration
│   ├── controllers/      # Request handlers
│   ├── middleware/       # Express middleware (auth, error handling)
│   ├── models/           # Mongoose models
│   ├── routes/           # API route definitions
│   ├── services/         # Business logic
│   ├── types/            # TypeScript type definitions
│   ├── utils/            # Utility functions
│   └── index.ts          # App entry point
├── dist/                 # Compiled JavaScript
├── .env.example          # Environment variables template
├── package.json
└── tsconfig.json
```

## Getting Started

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file based on `.env.example`

3. Start development server:
```bash
npm run dev
```

## Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Compile TypeScript to JavaScript
- `npm start` - Run production build
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues

## API Endpoints

### Auth
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - User logout

### Vehicles
- `GET /api/vehicles` - List user vehicles
- `POST /api/vehicles` - Create vehicle
- `GET /api/vehicles/:id` - Get vehicle details
- `PUT /api/vehicles/:id` - Update vehicle
- `DELETE /api/vehicles/:id` - Delete vehicle

### Fuel Logs
- `GET /api/fuel-logs` - List fuel logs
- `POST /api/fuel-logs` - Create fuel log
- `GET /api/fuel-logs/:id` - Get fuel log
- `PUT /api/fuel-logs/:id` - Update fuel log
- `DELETE /api/fuel-logs/:id` - Delete fuel log

### Service Logs
- `GET /api/service-logs` - List service logs
- `POST /api/service-logs` - Create service log
- `GET /api/service-logs/:id` - Get service log
- `PUT /api/service-logs/:id` - Update service log
- `DELETE /api/service-logs/:id` - Delete service log

### Reminders
- `GET /api/reminders` - List reminders
- `POST /api/reminders` - Create reminder
- `GET /api/reminders/:id` - Get reminder
- `PUT /api/reminders/:id` - Update reminder
- `DELETE /api/reminders/:id` - Delete reminder

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 3000) |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `JWT_ACCESS_SECRET` | Secret for access tokens |
| `JWT_REFRESH_SECRET` | Secret for refresh tokens |
| `JWT_ACCESS_EXPIRES_IN` | Access token expiry (e.g., '15m') |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiry (e.g., '7d') |
| `CORS_ORIGIN` | Allowed CORS origins (comma-separated) |
