# Backend README

## Apercu
Backend FastAPI (Python 3.12) avec Postgres et Flyway via Docker Compose.

## Prerequis
- Docker + Docker Compose
- PowerShell (pour utiliser le Makefile tel quel)
- Fichier `.env` a partir de `.env.example` (variables POSTGRES_*)

## Variables d'environnement
Copier l'exemple puis ajuster si besoin :
```bash
cp .env.example .env
```
Champs principaux :
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_PORT` (port expose sur la machine)

## Commandes Make (base de donnee)
- `make db-start` : demarre uniquement Postgres.
- `make db-migrate` : lance Flyway sur la DB.
- `make db-status` : verifie les migrations (echoue si pending).
- `make db-reset` : drop volume, recree Postgres, rejoue les migrations.
- `make db-stop` : arrete les conteneurs.
- `make db-remove-all` : stop + supprime volumes/images orphelines.

## Commandes Make (backend)
- `make backend-start` : build + demarre le service backend.
- `make test-db_conn` : ping de l'endpoint health (http://localhost:8000/health).

## Lancement manuel via Docker Compose
```bash
docker compose up --build db backend
# ou tout (db, flyway, backend)
docker compose up --build
```

## Healthcheck
Endpoint : `GET /health` (verifie la DB via le pool async).
```bash
curl http://localhost:8000/health
```

## Notes
- Le backend utilise un pool async psycopg; il est ouvert/ferme dans le lifespan FastAPI.
- Si vous changez `POSTGRES_DB`, recreez la base (ex: `make db-reset`) ou adaptez vos connexions clients (Beekeeper, psql, etc.).
