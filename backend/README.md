# Backend README

## Setup

1) Environment variables
```bash
cp .env.example .env
```

2) Start database + migrations
```bash
make db-start
make db-migrate
```

3) Start backend + worker
```bash
make backend-start
```

4) Health check
```bash
make backend-db-conn
```

## Auth header (Thunder Client)
- Key: `Authorization`
- Value: `Bearer <token>`

## Default admin
- Seeded by `db/migrations/V2__seed_admin.sql`
- Email: `admin@example.com`
- Password: `admin`

## Example requests (curl)
- Health: `curl.exe http://localhost:8000/health`
- Signup: `curl.exe -X POST http://localhost:8000/auth/signup -H "Content-Type: application/json" -d '{"first_name":"Test","last_name":"User","email":"user@example.com","password":"test123","roles":["FAN"]}'`
- Login: `curl.exe -X POST http://localhost:8000/auth/login -H "Content-Type: application/json" -d '{"email":"user@example.com","password":"test123"}'`
- Protected: `curl.exe http://localhost:8000/auth/me -H "Authorization: Bearer <token>"`
- Match details: `curl.exe "http://localhost:8000/matches/1" -H "Authorization: Bearer <token>"`

## Endpoints

Public:
- `GET /health`
- `GET /matches/previews`
- `GET /matches/rankings`

Auth:
- `POST /auth/signup`
- `POST /auth/login`
- `GET /auth/me` (auth)

Matches:
- `GET /matches/{match_id}` (auth)

Scheduler:
- `POST /scheduler/run`
- `GET /scheduler/status`

User (manager):
- `GET /user/manager/team` (role MANAGER)
- `POST /user/manager/team` (role MANAGER)
- `PUT /user/manager/team` (role MANAGER)
- `GET /user/manager/team/players` (role MANAGER)
- `POST /user/manager/team/players` (role MANAGER)
- `DELETE /user/manager/team/players/{player_id}` (role MANAGER)
- `GET /user/manager/team/players/available` (role MANAGER)

User (referee):
- `GET /user/referee/availability` (role REFEREE)
- `POST /user/referee/availability` (role REFEREE)
- `PUT /user/referee/availability` (role REFEREE)
- `DELETE /user/referee/availability/{slot_id}` (role REFEREE)
- `GET /user/referee/openslots` (role REFEREE)
- `GET /user/referee/matches` (role REFEREE)
- `GET /user/referee/history` (role REFEREE)

User (fan):
- `GET /user/favorites/teams` (role FAN+)
- `POST /user/favorites/teams` (role FAN+)
- `DELETE /user/favorites/teams/{team_id}` (role FAN+)
- `GET /user/subscriptions/teams` (role FAN+)
- `POST /user/subscriptions/teams` (role FAN+)
- `DELETE /user/subscriptions/teams/{team_id}` (role FAN+)
- `GET /user/subscriptions/players` (role FAN+)
- `POST /user/subscriptions/players` (role FAN+)
- `DELETE /user/subscriptions/players/{player_id}` (role FAN+)
- `GET /user/notifications` (role FAN+)
- `PUT /user/notifications` (role FAN+)

Admin:
- `POST /user/admin/role-keys` (role ADMIN)
- `GET /user/admin/console/matches` (role ADMIN)
- `POST /user/admin/console/matches/{match_id}/goal` (role ADMIN)
- `POST /user/admin/console/matches/{match_id}/card` (role ADMIN)
- `POST /user/admin/console/matches/{match_id}/substitution` (role ADMIN)
- `POST /user/admin/console/matches/{match_id}/finalize` (role ADMIN)
- `GET /user/admin/console/rankings/{division}` (role ADMIN)
- `GET /user/admin/console/teams/{team_id}/players` (role ADMIN)
- `POST /user/admin/scheduler/run` (role ADMIN)
- `POST /user/admin/pop_players` (role ADMIN)

## Worker (RQ + Redis)
- Queue name: `scheduler`
- Worker start: `docker compose up --build worker`
- Jobs: scheduler and referee assignment are enqueued via Redis
