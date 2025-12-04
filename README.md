# Community Sports League – Dev Environment

## Infos générales
### Description
Community Sports League est un projet étudiant au sein de la HESSO Valais-Wallis. Les objectifs sont les suivants :
- Gestion de base de donnée
- ORM 
- Application avec portails (admin, fan, manager, referee, public)

### Prérequis

- Docker + Docker Compose
- Git

### Images utilisées dans Docker
- Postgres:18
- Flyway:11

### Outils extenes 
- Visualisation : [dbdiagram.io](https://dbdiagram.io/home)

## Setup

### Cloner le dépôt 
```bash
git clone https://github.com/DB-GL-Group/Community-Sports-League-Scheduler-Stats.git
cd Community-Sports-League-Scheduler-Stats
```

### Variables d'environnement (Obligatoire)
```bash
cp .env.example .env # Modifier les variables si besoin
```

## Commandes

```bash
# Starts the db
make db-start

# Stops the db
make db-stop

# Checks migrations sync
make db-status

# Applies migrations
make db-migrate

# Removes the container and its volumes
make db-remove-all

# Rebuilds everything from scratch
make db-reset
```
## Workflow
```bash
make db-start
make db-status
make db-migrate 
# ...
make db-stop
```


## Accès à la base de données
La base de données PostgreSQL sera accessible sur le port défini dans le fichier `.env` (par défaut `5432`). \
Utilise un client PostgreSQL (comme `psql`, DBeaver, ou Beekeeper studio) pour te connecter avec les informations d'identification définies dans le fichier `.env`. 

### Exemple avec `psql` :

```bash
docker exec -it sports-league-db psql -U <user> -d sports_league 
```

### Exemple avec `Beekeeper Studio` :
- Host: `localhost`
- Port: `5432` (ou celui défini dans `.env`)
- User: `<user>` (défini dans `.env`)
- Password: `<password>` (défini dans `.env`)
- Database: `sports_league` (défini dans `.env`)

## Modifier la base de données
Toute modification de la structure doit être ajoutée dans un fichier SQL dans le dossier `db/migrations/`. \
Les fichiers suivent la convention de nom suivante : 
```
Versioned  : "V<version>__<desciption>.sql"
Undo       : "U<version>__<description>.sql"
Repeatable : "R<version>__<description>.sql"
```
Au démarrage du conteneur, tous les scripts SQL dans ce dossier seront exécutés automatiquement pour initialiser la base de données. \
Depuis Beekeeper Studio, il s'agit des requêtes exécutées.
