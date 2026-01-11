# Backend README

## Setup
1) **Modifier les variables dans .env** 
``` bash
# JWT config
JWT_SECRET=aprettysecuresecretkeythatyoushouldchange
JWT_ALGORITHM=HS256
JWT_EXPIRES_MINUTES=60
```

2) **Générer une clé secrète JWT sécurisée** (optionnel mais recommandé):
- PowerShell: `[Convert]::ToBase64String((1..64|%{Get-Random -Max 256}|%{[byte]$_}))`)

3) **Démarrer le backend**: 
``` bash 
make backend-start
```

4) **Test**:
``` bash
make backend-db-conn # Vérifie que le backend répond
```

## Exemples de requêtes (frontend ou curl)
  - **Health**: `curl.exe http://localhost:8000/health`
  - **Signup**: `curl.exe -X POST http://localhost:8000/auth/signup -H "Content-Type: application/json" -d '{"first_name":"Test","last_name":"User","email":"user@example.com","phone":"+10000000000","password":"test123","roles":["FAN"]}'`
  - **Login**: `curl.exe -X POST http://localhost:8000/auth/login -H "Content-Type: application/json" -d '{"email":"user@example.com","password":"test123"}'`
  - **Profil protégé**: `curl.exe http://localhost:8000/auth/me -H "Authorization: Bearer <token>"`
  - **Match details (protected)**: `curl.exe "http://localhost:8000/matches/1" -H "Authorization: Bearer <token>"`

## Auth header (Thunder Client)
- Add a header:
  - Key: `Authorization`
  - Value: `Bearer <token>`

## Endpoints
- Public:
  - `GET /health`
  - `GET /matches/previews`
- Auth:
  - `POST /auth/signup`
  - `POST /auth/login`
  - `GET /auth/me` (auth)
- Matches:
  - `GET /matches/{match_id}` (auth)
- Scheduler:
  - `POST /scheduler/run`
  - `GET /scheduler/status`
- User (manager):
  - `GET /user/manager/team` (role MANAGER)
  - `POST /user/manager/team` (role MANAGER)
- User (referee):
  - `GET /user/referee/availability` (role REFEREE)
  - `POST /user/referee/availability` (role REFEREE)
  - `PUT /user/referee/availability` (role REFEREE)
  - `DELETE /user/referee/availability/{slot_id}` (role REFEREE)
  - `GET /user/referee/matches` (role REFEREE)
- User (fan):
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


## Backend-DB
- Flux auth (orchestration) :
  - Entrée API : `routers/auth.py` définit `/auth/signup`, `/auth/login`, `/auth/me`.
  - Logique métier : `services/auth.py` (hash argon2, création/validation JWT, contrôles d’état utilisateur).
  - Accès SQL : `repositories/users.py` (lecture hash/roles, insertion user, agrégation des rôles) via pool async `shared/db.py`.
  - Connexion : pool `AsyncConnectionPool` ouvert/fermé dans le lifespan FastAPI (`main.py`).
  - Schéma : tables `users`, `roles`, `user_roles` définies dans `db/migrations/V1__init.sql` (rôles init FAN, MANAGER, REFEREE, ADMIN).


## Backend-Frontend
- Auth/API disponibles:
  - `POST /auth/signup` : crée un utilisateur (hash argon2, associe rôles existants).
  - `POST /auth/login` : retourne `access_token` (Bearer JWT) + info user.
  - `GET /auth/me` : nécessite `Authorization: Bearer <token>`, retourne l’utilisateur courant.
- Intégration front: envoyer le token JWT dans l’en-tête `Authorization: Bearer <token>` sur chaque requête protégée; le backend vérifie le token et les rôles avant d’exécuter la logique.

## Worker (RQ + Redis)
- Demarrer les services: `docker compose up --build`
- Lancer un job: `POST /scheduler/run`
- Suivre un job: `GET /scheduler`



